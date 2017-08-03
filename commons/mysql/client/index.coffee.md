
# MySQL client

Install the MySQL command-line tool.

    module.exports =
      use:
        mysql_server: module: 'masson/commons/mysql/server'
      configure: 'masson/commons/mysql/client/configure'
      commands:
        'install': 'masson/commons/mysql/client/install'
