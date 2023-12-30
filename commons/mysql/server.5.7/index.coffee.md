
# Mysql Server

Install MySQL Server 5.7 community.

    export default
      deps:
        iptables: module: 'masson/core/iptables', local: true
      configure:
        'masson/commons/mysql/server.5.7/configure'
      commands:
        'check':
          'masson/commons/mysql/server.5.7/check'
        'install': [
          'masson/commons/mysql/server.5.7/install'
          'masson/commons/mysql/server.5.7/check'
        ]
        'start':
          'masson/commons/mysql/server/start'
        'stop':
          'masson/commons/mysql/server/stop'
