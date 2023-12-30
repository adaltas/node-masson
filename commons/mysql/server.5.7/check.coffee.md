
# Mysql Server Check

    export default header: 'Mysql Server Check', handler: (options) ->

## Runing Sevrice

Ensure the "ntpd" service is up and running.

      @service.assert
        header: 'Service'
        if_exec: 'yum info mysql-community-server'
        name: 'mysql-community-server'
        started: true

## Wait Connect

Wait connect action is used as a check n the port availability.

      @connection.assert
        host: options.wait_tcp.fqdn
        port: options.wait_tcp.port

## Dependencies

    db = require '@nikitajs/core/lib/misc/db'
