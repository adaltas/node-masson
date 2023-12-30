
# Mysql Server

TODO: https://dev.mysql.com/doc/refman/5.7/en/mysql-cluster.html

    export default
      deps:
        iptables: module: 'masson/core/iptables', local: true
      configure:
        'masson/commons/mysql/server/configure'
      commands:
        'check':
          'masson/commons/mysql/server/check'
        'install': [
          'masson/commons/mysql/server/install'
          'masson/commons/mysql/server/check'
        ]
        'start':
          'masson/commons/mysql/server/start'
        'stop':
          'masson/commons/mysql/server/stop'
