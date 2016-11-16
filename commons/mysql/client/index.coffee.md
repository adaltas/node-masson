
# Mysql

Install the MySQL command-line tool.

    module.exports =
      commands:
        'install': handler: ->

## Package

Install the Mysql client.

          @service
            header: 'Mysql Client # Package'
            name: 'mysql'

## Connector

Install the Mysql JDBC driver.

          @service
            header: 'Mysql Client # Connector'
            name: 'mysql-connector-java'
