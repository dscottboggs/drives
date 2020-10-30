import os, tables, strformat, parseutils, unicode, math, strutils
import regex

# const driveAbbrRegex* = rex"([a-zA-Z])([0-9]*)$"
const labelsDir = "/dev/disk/by-label"
const uuidsDir = "/dev/disk/by-uuid"
const desiredWidth = 84

type
    Drive* = ref object
        path*: string
        uuid*: string
        label*: string
        size*: uint

proc getDeviceOrPartitionSize(id: string): uint =
    discard readFile(&"/sys/class/block/{id}/size").`$`.parseUInt(result)
    result *= 512

iterator findDrives*(): Drive =
    var labels = initTable[string, string]()
    for (kind, label) in walkDir(labelsDir, false):
        if kind != pcLinkToFile:
            echo &"warning: found file of type '{kind}' at {label}"
            continue
        let path = label.expandSymlink.absolutePath(root=labelsDir)
        labels[path] = label.lastPathPart
    for (kind, uuid) in walkDir(uuidsDir, false):
        if kind != pcLinkToFile:
            echo &"warning: found file of type '{kind}' at {uuid}"
            continue
        let dev = uuid.expandSymlink.absolutePath(uuidsDir)
        yield Drive(
            path: dev,
            uuid: uuid.lastPathPart,
            label: labels.getOrDefault(dev, ""),
            size: dev.lastPathPart.getDeviceOrPartitionSize
        )

proc abbr*(drive: Drive): string {.raises: [Exception].} =
    match drive.path, rex"([a-zA-Z])([0-9]*)$":
        return matches.join("").toUpper
    raise Exception.newException(&"couldn't find abbreviation for device {drive.path}")

proc readableSize(size: uint): string =
    ## TODO switch to filesize or bytes2human libraries
    if size < (1 shl 30).uint:
        result = $round(float(size) / 1024, 2) & " kB"
    else:
        result = $round(size.float / (1 shl 30).float) & " GB"

proc `$`*(drive: Drive): string = 
    let size = readableSize drive.size
    result = &"{drive.abbr}:\t{readableSize drive.size}"
    for _ in 0..<20 - len(size):
        result &= ' '
    result &= drive.label
    let padding = desiredWidth - result.len - drive.uuid.len - 6
    for _ in 0..<padding:
        result &= ' '
    result &= drive.uuid

when isMainModule:
    for drive in findDrives():
        echo $drive
