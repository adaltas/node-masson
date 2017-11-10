
# MySQL client

Install the MySQL command-line tool.

    module.exports =
      deps:
        mysql_server: module: 'masson/commons/mysql/server', single: true
      configure: 'masson/commons/mysql/client/configure'
      commands:
        'install':
          'masson/commons/mysql/client/install'
