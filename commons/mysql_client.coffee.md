
# Mysql

Install the MySQL command-line tool.

    exports = module.exports = []
    exports.push 'masson/core/yum'
    exports.push 'masson/bootstrap'

## Package

Install the Mysql client.

    exports.push name: 'Mysql Client # Package', callback: (ctx, next) ->
      ctx.service
        name: 'mysql'
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

## Connector

Install the Mysql JDBC driver.

    exports.push name: 'Mysql Client # Connector', timeout: -1, callback: (ctx, next) ->
      ctx.service
        name: 'mysql-connector-java'
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS



