
# LVM Install

    export default header: 'LVM Install', handler: ({options}) ->

## Initialize physical volume

Initializes physical volume for use by LVM.

      @system.execute
        header: 'Initializing physical volume'
        cmd: "pvcreate #{options.disk}"
        code_skipped: 5

## Volume group extension

Extends target volume group.

      @system.execute
        header: 'Extending volume group'
        cmd: "vgextend #{options.vg} #{options.disk}"
        code_skipped: 5

## Logical volume extension

Extends target logical volume.

      @system.execute
        header: 'Extending logical volume'
        cmd: "lvextend -L #{options.size} #{options.lv}"
        code_skipped: 5

## Check filesystem

Resizes the logical volume to make the changes effective.

      @system.execute
        header: 'Resizing the logical volume'
        cmd: "fsadm resize #{options.lv}"
