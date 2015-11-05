
# Mysql

Install the MySQL command-line tool.

    exports = module.exports = []
    exports.push 'masson/core/yum'
    exports.push 'masson/bootstrap'

## Package

Install the Mysql client.

    exports.push header: 'Mysql Client # Package', handler: ->
      @service
        name: 'mysql'

## Connector

Install the Mysql JDBC driver.

    exports.push header: 'Mysql Client # Connector', timeout: -1, handler: ->
      @service
        name: 'mysql-connector-java'
