

export default
  deps:
    'system': module: 'masson/core/system', local: true
    'proxy': module: 'masson/core/proxy', local: true
  configure:
    'masson/commons/git/configure'
  commands:
    'install':
      'masson/commons/git/install'
