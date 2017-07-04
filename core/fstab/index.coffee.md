
# FSTAB

This module handles fstab and mountpoints.

    module.exports =
      use: {}
      'configure':  'masson/core/fstab/configure'
      commands:
        'check': ->
          options = @config.fstab
          @call 'masson/core/fstab/check', options
        'install': ->
          options = @config.fstab
          @call 'masson/core/fstab/install', options
          @call 'masson/core/fstab/check', options
