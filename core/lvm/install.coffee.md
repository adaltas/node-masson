
# LVM Install

    module.exports = header: 'LVM Install', handler: ->
      {system} = @config

## Initialize physical volume

Initializes physical volume for use by LVM.

      @system.execute
        header: 'Initializing physical volume'
        cmd: "pvcreate #{@config.lvm.disk}"
        code_skipped: 5

## Volume group extension

Extends target volume group.

      @system.execute
        header: 'Extending volume group'
        cmd: "vgextend #{@config.lvm.vg} #{@config.lvm.disk}"
        code_skipped: 5

## Logical volume extension

Extends target logical volume.

      @system.execute
        header: 'Extending logical volume'
        cmd: "lvextend -L #{@config.lvm.size} #{@config.lvm.lv}"
        code_skipped: 5

## Check filesystem

Resizes the logical volume to make the changes effective.

      @system.execute
        header: 'Resizing the logical volume'
        cmd: "fsadm resize #{@config.lvm.lv}"
