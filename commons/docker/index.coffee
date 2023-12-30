
export default
  deps:
    iptables: module: 'masson/core/iptables', local: true
    ssl: module: '@rybajs/tools/ssl', local: true
  configure:
    'masson/commons/docker/configure'
  commands:
    'check':
      'masson/commons/docker/check'
    'install': [
      'masson/commons/docker/install'
      'masson/commons/docker/start'
      'masson/commons/docker/check'
    ]
    'prepare':
      'masson/commons/docker/prepare'
    'start':
      'masson/commons/docker/start'
    'status':
      'masson/commons/docker/status'
    'stop':
      'masson/commons/docker/stop'
