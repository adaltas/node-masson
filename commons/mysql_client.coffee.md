---
title: 
layout: module
---

# Mysql

Install the MySQL command-line tool.

    module.exports = []
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/bootstrap/'

## Package

Install the Mysql client.

    module.exports.push name: 'Mysql Client # Package', callback: (ctx, next) ->
      ctx.service
        name: 'mysql'
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

## Connector

Install the Mysql JDBC driver.

    module.exports.push name: 'Mysql Client # Connector', timeout: -1, callback: (ctx, next) ->
      # todo: below doesnt declare the mysql jar inside the hive lib folder
      # /usr/share/java/mysql-connector-java.jar
      ctx.service
        name: 'mysql-connector-java'
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS



