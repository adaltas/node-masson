
# Mysql

Install the MySQL command-line tool.

    module.exports =
      commands:
        'install': header: 'MySQL Client Install', handler: ->

## Package

Install the Mysql client.

          @service
            header: 'Package'
            name: 'mysql'

## Connector

Install the Mysql JDBC driver.

          @service
            header: 'Connector'
            name: 'mysql-connector-java'
