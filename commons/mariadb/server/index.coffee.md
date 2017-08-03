
# MariaDB Server

TODO: https://dev.mysql.com/doc/refman/5.7/en/mysql-cluster.html

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: 'masson/core/ssl', local: true
        mariadb: module: 'masson/commons/mariadb/server'
      configure:
        'masson/commons/mariadb/server/configure'
      commands:
        'check': ->
          options = @config.mariadb.server
          @call 'masson/commons/mariadb/server/check', options
        'install': ->
          options = @config.mariadb.server
          @call 'masson/commons/mariadb/server/install', options
          @call 'masson/commons/mariadb/server/replication', options
          @call 'masson/commons/mariadb/server/check', options
        'stop': ->
          options = @config.mariadb.server
          @call 'masson/commons/mariadb/server/stop', options
        'start': ->
          options = @config.mariadb.server
          @call 'masson/commons/mariadb/server/start', options
        'check': ->
          options = @config.mariadb.server
          @call 'masson/commons/mariadb/server/check', options
