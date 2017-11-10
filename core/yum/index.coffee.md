
# YUM

    module.exports =
      deps:
        proxy: module: 'masson/core/proxy'
      configure:
        'masson/core/yum/configure'
      commands:
        # 'prepare': ->
        #   options = @config.yum
        #   @call 'masson/core/yum/prepare', options
        'install':
          'masson/core/yum/install'
