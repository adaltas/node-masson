
# Mysql Server

TODO: https://dev.mysql.com/doc/refman/5.7/en/mysql-cluster.html

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
      configure:
        'masson/commons/mysql/server/configure'
      commands:
        'check': ->
          options = @config.mysql.server
          @call 'masson/commons/mysql/server/check', options
        'install': ->
          options = @config.mysql.server
          @call 'masson/commons/mysql/server/install', options
          @call 'masson/commons/mysql/server/check', options
        'start':
          'masson/commons/mysql/server/start'
        'stop':
          'masson/commons/mysql/server/stop'
