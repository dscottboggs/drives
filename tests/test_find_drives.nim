import unittest

import drivespkg/find_drives

test "abbreviation of /dev/sdc1":
    check Drive(label: "test", uuid: "1234", path: "/dev/sdc1").abbr == "C1"