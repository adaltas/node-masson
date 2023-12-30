
export default
  deps:
    iptables: module: 'masson/core/iptables', local: true
    docker: module: 'masson/commons/docker', local: true
  configure:
    'masson/commons/postgres/server/configure'
  commands:
    'check':
      'masson/commons/postgres/server/check'
    'install': [
      'masson/commons/postgres/server/install'
      'masson/commons/postgres/server/start'
      'masson/commons/postgres/server/check'
    ]
    'prepare':
      'masson/commons/postgres/server/prepare'
    'start':
      'masson/commons/postgres/server/start'
    'stop':
      'masson/commons/postgres/server/stop'
