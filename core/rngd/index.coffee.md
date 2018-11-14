
# RNGD

Install RNGD Service to avoid beeing out of entropy by replacing /dev/urandom by /dev/random
device.

    module.exports =
      deps:
        yum: module: 'masson/core/yum'
      configure:
        'masson/core/rngd/configure'
      commands:
        'install':
          'masson/core/rngd/install'
