
# PostgreSQL

Install the PotsgreSQL command-line tool.

    module.exports = ->
      'install': handler: ->

## Package

Install the Mysql client.

        @service
          header: 'PostgreSQL Package'
          name: 'postgresql'

## Connector

Install the Mysql JDBC driver.

        @service
          header: 'PostgreSQL Connector'
          name: 'postgresql-jdbc'
