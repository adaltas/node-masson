
# YUM

    module.exports =
      use:
        proxy: 'masson/core/proxy'
        ntp: 'masson/core/ntp'
      configure: [
        'masson/bootstrap/fs'
        'masson/core/yum/configure'
      ]
      commands:
        'install':
          'masson/core/yum/install'
