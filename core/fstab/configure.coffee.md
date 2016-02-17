
# FSTAB Configure

    module.exports = handler: ->
      fstab = @config.fstab ?= {}
      fstab.enabled ?= false
      fstab.exhaustive ?= false
      fstab.volumes ?= {}
      if fstab.enabled then for mntpt, disk of fstab.volumes
        disk.options ?= 'defaults'
        disk.dump ?= '0'
        disk.pass ?= '0'
        disk.dump = "#{disk.dump}" if typeof disk.dump isnt 'string'
        disk.dump = "#{disk.dump}" if typeof disk.pass isnt 'string'
        throw Error "Please specify device property for mountpoint #{mntpt} or disable fstab" unless disk.device?
        throw Error "Invalid device format. Please provide a string (device path or UUID='<uuid>')" unless typeof disk.device is 'string'
        throw Error "Please specify 'type' property for mountpoint #{mntpt} or disable fstab" unless disk.type?
        throw Error "Invalid dump property for '#{mntpt}', please set to 0 or 1" unless disk.dump in ['0', '1']
        throw Error "Invalid pass property for '#{mntpt}', please set to 0, 1, or 2" unless disk.pass in ['0', '1', '2']
