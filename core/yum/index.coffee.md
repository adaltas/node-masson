
# YUM

    module.exports =
      use:
        proxy: 'masson/core/proxy'
      configure: [
        'masson/bootstrap/fs'
        'masson/core/yum/configure'
      ]
      commands:
        'install':
          'masson/core/yum/install'
