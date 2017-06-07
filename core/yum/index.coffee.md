
# YUM

    module.exports =
      use:
        proxy: 'masson/core/proxy'
      configure: [
        'masson/bootstrap/fs'
        'masson/core/yum/configure'
      ]
      commands:
        'prepare': ->
          options = @config.yum
          @call 'masson/core/yum/prepare', options
        'install': ->
          options = @config.yum
          @call 'masson/core/yum/install', options
