
# MySQL client

Install the MySQL command-line tool.

    module.exports =
      use:
        mysql_server: module: 'masson/commons/mysql/server', single: true
      configure: 'masson/commons/mysql/client/configure'
      commands:
        'install': ->
          options = @config.mysql.client
          @call 'masson/commons/mysql/client/install', options
