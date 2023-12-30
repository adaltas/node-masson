
export default
  deps:
    proxy: module: 'masson/core/proxy/index'
  configure:
    'masson/core/yum/configure'
  commands:
    # 'prepare': ->
    #   options = @config.yum
    #   @call 'masson/core/yum/prepare', options
    'install':
      'masson/core/yum/install'
