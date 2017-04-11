
# Mysql Server

TODO: https://dev.mysql.com/doc/refman/5.7/en/mysql-cluster.html

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
      configure:
        'masson/commons/mariadb/server/configure'
      commands:
        'install': [
          'masson/commons/mariadb/server/install'
          'masson/commons/mariadb/server/replication'
          'masson/commons/mariadb/server/check'
        ]
