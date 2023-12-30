
# FSTAB Configure

Configure volume and mount point to write into fstab. to prepare the disk administrators
can set the `disk.format` options to the desired format or setting to true will use
default format ext4. In this case the device should be the name of the disk.

Example 1
```json
{ "fstab": {
    "volumes":
      "/data/1":
        "dump": "0"
        "pass": "0"
        "device": "/dev/vg_root"
        "type": "xfs"
        "format": false
  }
  result:
    /dev/vg_root /data/1  xfs     defaults        0 0 
}
```

Example 1 with format preparation
```json
{ "fstab": {
    "volumes":
      "/data/1":
        "dump": "0"
        "pass": "0"
        "name": "sdd"
        "type": "xfs"
        "format": true
  }
  result:
    /dev/vg_root /data/1  xfs     defaults        0 0 
}
```

    export default (service) ->
      options = service.options
      options.enabled ?= false
      options.exhaustive ?= false
      options.volumes ?= {}
      if options.enabled then for mntpt, disk of options.volumes
        disk.options ?= 'defaults'
        disk.dump ?= '0'
        disk.pass ?= '0'
        disk.dump = "#{disk.dump}" if typeof disk.dump isnt 'string'
        disk.pass = "#{disk.pass}" if typeof disk.pass isnt 'string'
        disk.name = path.resolve '/dev/', disk.name if disk.format
        throw Error "Please specify device property for mountpoint #{mntpt} or disable fstab" unless disk.device? or disk.name?
        throw Error "Invalid device format. Please provide a string (device path or UUID='<uuid>')" unless typeof disk.device is 'string' or disk.format
        throw Error "Please specify 'type' property for mountpoint #{mntpt} or disable fstab" unless disk.type?
        throw Error "Type is not supported" if disk.format and disk.type not in ['ext4','ext3','ext2']
        throw Error "can not prodived disk.device and disk.name" if disk.device? and disk.name?
        throw Error "Missing disk name " if disk.format and not disk.name?
        throw Error "Invalid dump property for '#{mntpt}', please set to 0 or 1" unless disk.dump in ['0', '1']
        throw Error "Invalid pass property for '#{mntpt}', please set to 0, 1, or 2" unless disk.pass in ['0', '1', '2']

## Dependencies

    path = require 'path'
