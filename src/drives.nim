import find_drives

when isMainModule:
  for drive in findDrives():
    echo $drive
