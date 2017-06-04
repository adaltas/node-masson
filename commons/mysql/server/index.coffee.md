
# Mysql Server

TODO: https://dev.mysql.com/doc/refman/5.7/en/mysql-cluster.html

    module.exports =
      use:
        iptables: module: 'masson/core/iptables' #implicit: true, 
      configure:
        'masson/commons/mysql/server/configure'
      commands:
        'install': [
          'masson/commons/mysql/server/install'
          'masson/commons/mysql/server/check'
        ]
        'start':
          'masson/commons/mysql/server/start'
        'stop':
          'masson/commons/mysql/server/stop'
