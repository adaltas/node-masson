
# Krb5 Client Wait

Wait for all the Kerberos servers referenced by the client configuration.

## Wait TCP

    module.exports = header: 'Krb5 Client Wait', handler: ->
      {krb5} = @config
      @connection.wait
        header: 'TCP Admin'
        servers: for realm, config of krb5.etc_krb5_conf.realms
          continue unless config.admin_server
          [host, port] = config.admin_server.split ':'
          host: host
          port: port or 749

## Wait Admin

Wait for the admin interface to be ready by issuing the command `listprincs`.
Option "retry" is set to "2" because we get a lot of "null exit code" errors
and we couldnt dig the exact nature of this error.

      @call header: 'Command kadmin', retry: 2, handler: ->
        for realm, config of krb5.etc_krb5_conf.realms
          continue unless config.kadmin_principal and config.admin_server
          @wait.execute 
            retry: 5
            interval: 10000
            cmd: misc.kadmin
              realm: realm
              kadmin_principal: config.kadmin_principal
              kadmin_password: config.kadmin_password
              kadmin_server: config.admin_server
            , 'listprincs'
            stdin_log: true
            stdout_log: false
            stderr_log: false

## Module Dependencies

    misc = require 'nikita/lib/misc'
