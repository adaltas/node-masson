
# PostgreSQL Client

Install the PostgreSQL command-line tool.

    export default header: 'PostgreSQL Client Install', handler: ->

## Package

Install the PostgreSQL client.

      @service
        header: 'PostgreSQL Package'
        name: 'postgresql'

## Connector

Install the PostgreSQL JDBC driver.

      @service
        header: 'PostgreSQL Connector'
        name: 'postgresql-jdbc'
