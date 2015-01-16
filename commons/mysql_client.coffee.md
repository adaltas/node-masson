
# Mysql

Install the MySQL command-line tool.

    exports = module.exports = []
    exports.push 'masson/core/yum'
    exports.push 'masson/bootstrap'

## Package

Install the Mysql client.

    exports.push name: 'Mysql Client # Package', handler: (ctx, next) ->
      ctx.service
        name: 'mysql'
      , next

## Connector

Install the Mysql JDBC driver.

    exports.push name: 'Mysql Client # Connector', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'mysql-connector-java'
      , next



