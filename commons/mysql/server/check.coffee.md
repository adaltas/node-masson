
# Mysql Server Check

    export default header: 'Mysql Server Check', handler: (options) ->

## Runing Service

      @service.assert
        header: 'Service'
        if_exec: 'yum info mysql-community-server'
        name: 'mysql-community-server'
        srv_name: 'mysqld'
        started: true
      @service.assert
        header: 'Service'
        if_exec: 'yum info mysql-server'
        name: 'mysql-server'
        srv_name: 'mysqld'
        started: true

## Wait Connect

Wait connect action is used as a check of the port availability.

      @connection.assert
        host: options.wait_tcp.fqdn
        port: options.wait_tcp.port

## Dependencies

    db = require '@nikitajs/core/lib/misc/db'
