
# MariaDB Server Check

    module.exports = header: 'MariaDB Server Check', handler: ({options}) ->

## Runing Sevrice

Ensure the "ntpd" service is up and running.

      @service.assert
        header: 'Service'
        name: options.name
        srv_name: options.srv_name
        installed: true
        started: true

## TCP Connection

Ensure the port is listening.

      @connection.wait
        retry: 3
        interval: 10000
      @connection.assert
        header: 'TCP'
        host: options.wait_tcp.fqdn
        port: options.wait_tcp.port

## Check Replication

      @call
        header: 'Replication'
        if: options.ha_enabled
      , ->
        props =
          database: null
          admin_username: options.admin_username
          admin_password: options.admin_password
          engine: 'mysql'
          host: 'localhost'
          silent: false
        @system.execute
          retry: 3
          cmd: "#{cmd admin_username:props.admin_username, admin_password:props.admin_password, engine:props.engine, host:props.host, cmd:'show slave status \\G ;'} | grep Slave_IO_State"
        , (err, data) ->
          throw err if err
          ok = /^Slave_IO_State:\sWaiting for master to send event/.test(data.stdout.trim() )or /^Slave_IO_State:\sConnecting to master/.test(data.stdout.trim())
          throw Error 'Error in Replication state' unless ok

## Dependencies

    {cmd} = require '@nikitajs/db/lib/query'
