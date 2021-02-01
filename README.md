# GithubActions Script
This repo contains some useful script to run build in Github Actions.

```
twrp.sh	: Run TWRP build.
Usage:
	./twrp.sh <devicecodename> <twrpbranch> <buildtype> <recoverytype>

<devicecodename>: Device codename. Ex: a51, j4lte, kenzo.
<twrpbranch>: TWRP branch number. Ex: 10.0, 9.0, 8.1.
<buildtype>: Build type. Ex: eng, userdebug.
<recoverytype>: Recovery type. Ex: recovery, boot. This is based on device. Recovery for recovery partition. Boot for device with only have boot partition.

Example:
	./twrp.sh a51 10.0 userdebug recovery

```

More script soon :)
