
# MariaDB Server

TODO: https://dev.mysql.com/doc/refman/5.7/en/mysql-cluster.html

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        ssl: implicit: true, module: 'masson/core/ssl'
      configure:
        'masson/commons/mariadb/server/configure'
      commands:
        'install': ->
          options = @config.mariadb
          @call 'masson/commons/mariadb/server/install', options
          @call 'masson/commons/mariadb/server/replication', options
          @call 'masson/commons/mariadb/server/check', options
        'stop': ->
          options = @config.mariadb
          @call 'masson/commons/mariadb/server/stop', options
        'start': ->
          options = @config.mariadb
          @call 'masson/commons/mariadb/server/start', options
        'check': ->
          options = @config.mariadb
          @call 'masson/commons/mariadb/server/check', options
