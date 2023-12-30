
# FSTAB

This module handles fstab and mountpoints.

    export default
      configure:
        'masson/core/fstab/configure'
      commands:
        'check': [
          'masson/core/fstab/check'
        ]
        'install': [
          'masson/core/fstab/install'
          'masson/core/fstab/check'
        ]
          
