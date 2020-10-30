import std/enumerate, terminal, system, std/exitprocs, sequtils, strformat, strutils

import ./find_drives

type
    Menu = ref object
        drives: seq[Drive]
        selected: uint
    EventKind = enum
        Quit
        CycleMenu
        SelectItem
    ThreadData = (Menu, var Channel[EventKind])

const TABCHAR = '\t'

proc show(menu: Menu) =
    for idx, drive in enumerate menu.drives:
        if idx.uint == menu.selected:
            setStyle({styleReverse})
            echo $drive
            resetAttributes()
        else:
            echo $drive

proc reprint(menu: Menu) =
    for _ in 0..<menu.drives.len:
        eraseLine()
        cursorUp 1
    show menu

proc eventListener(data: (Menu, var Channel[EventKind])) {.thread, nimcall.} =
    let menu = data[0]
    var eventStream = data[1]
    while true:
        let chr = getch()
        stderr.write &"received input char {chr}\n"
        case chr
        of '\t': eventStream.send EventKind.CycleMenu
        of '\n': eventStream.send EventKind.SelectItem
        of 'q':
            eventStream.send EventKind.Quit
            return
        else:
            continue
        reprint menu

proc initializeMenu() =
    addExitProc resetAttributes
    var menu = Menu(drives: toSeq(findDrives()), selected: 0)
    var eventStream: Channel[EventKind]
    open eventStream
    defer:
        close eventStream
    show menu
    var worker: Thread[ThreadData]
    worker.createThread[ThreadData](eventListener, (menu, eventStream))
    while true:
        case eventStream.recv()
        of EventKind.CycleMenu:
            stderr.write "Menu-Cycle input received\n"
            if menu.selected < menu.drives.len.uint:
                inc menu.selected
            else:
                menu.selected = 0
        of EventKind.SelectItem:
            stderr.write "Select-Item input received\n"
            echo "selected drive:\n" & $menu.drives[menu.selected]
        of EventKind.Quit:
            stderr.write "received notice to quit\n"
            quit 0

when isMainModule:
    initializeMenu()