
# LVM Configure

The module accept the following properties:

*   `disk` (string)   
    The partition is a device name followed by a partition number.
    For example, /dev/sda1 is the first partition on the first hard disk in
    the system.   
*   `vg` (string)   
    Volume group to extend.   
*   `lv` (string)   
    Logical volume to extend.   
*   `size` (string)   
    Extends the logical volume size in units of megabytes. 
    A size suffix of M for megabytes, G for gigabytes, T for terabytes, P for petabytes or E for exabytes is optional.
    With the + sign the value is added to the actual size of the logical volume. 

    module.exports = ->
      @config.lvm ?= {}
      throw Error "Invalid device format. Please provide a string (device path or UUID='<uuid>')" unless typeof @config.lvm.disk is 'string'
      throw Error "Please provide a target volume group" unless typeof @config.lvm.vg is 'string'
      throw Error "Please provide a target logical volume" unless typeof @config.lvm.lv is 'string'
      throw Error "Please provide a target logical volume" unless typeof @config.lvm.size is 'string'
