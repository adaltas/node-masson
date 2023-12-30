
export default
  deps:
    yum: module: 'masson/core/yum'
  # configure:
  #   'masson/core/rngd/configure'
  commands:
    'install':
      'masson/core/rngd/install'
