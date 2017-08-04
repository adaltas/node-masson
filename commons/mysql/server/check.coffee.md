
# Mysql Server Check

    module.exports = header: 'Mysql Server Check', handler: ->
      {mysql} = @config

## Runing Sevrice

Ensure the "ntpd" service is up and running.

      @service.assert
        header: 'Service'
        if_exec: 'yum info mysql-community-server'
        name: 'mysql-community-server'
        started: true
      @service.assert
        header: 'Service'
        if_exec: 'yum info mysql-server'
        name: 'mysql-server'
        started: true

## Wait Connect
Wait connect action is used as a check n the port availability.

      @connection.wait
        port: mysql.server.my_cnf['mysqld']['port']
        host: @config.host

## Dependencies

    db = require 'nikita/lib/misc/db'
