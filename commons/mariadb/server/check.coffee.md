
# MariaDB Server Check

    module.exports = header: 'MariaDB Server Check', handler: (options) ->
      
      props =
        database: null
        admin_username: 'root'
        admin_password: options.password
        engine: 'mysql'
        host: @config.host
        silent: false

## Wait Connect
Wait connect action is used as a check n the port availability.

      @connection.wait
        port: options.my_cnf['mysqld']['port']
        host: @config.host

## Check Replication

      props =
        database: null
        admin_username: options.admin_username
        admin_password: options.admin_password
        engine: 'mysql'
        host: 'localhost'
        silent: false
      @call
        header: 'Check Replication'
        if: options.ha_enabled
        handler: ->
          @system.execute
            retry: 3
            cmd: "#{db.cmd props,'show slave status \\G ;'} | grep Slave_IO_State"
          , (err, status, stdout) ->
            throw err if err
            ok = /^Slave_IO_State:\sWaiting for master to send event/.test(stdout.trim() )or /^Slave_IO_State:\sConnecting to master/.test(stdout.trim())
            throw Error 'Error in Replication state' unless ok

## Dependencies

    db = require 'nikita/lib/misc/db'
