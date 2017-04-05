
# Mysql

Install the MySQL command-line tool.

    module.exports =
      commands:
        'install': handler: (options) ->

## Package

Install the Mysql client.

          @service.install 'mysql'

## Connector

Install the Mysql JDBC driver.

          @service
            header: 'Connector'
            name: 'mysql-connector-java'
