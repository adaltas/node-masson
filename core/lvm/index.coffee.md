
# Logical Volume Manager

Makes a physical volume out of a disk for LVM. 
Then it extends a given volume group with this disk and its targeted logical volume.

## Configuration

    export default
      configure:
        'masson/core/lvm/configure'
      commands:
        'install':
          'masson/core/lvm/install'
