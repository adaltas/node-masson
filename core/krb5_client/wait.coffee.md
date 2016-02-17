
# Krb5 Client Wait

Wait for all the Kerberos servers referenced by the client configuration.

## Wait TCP

    module.exports = header: 'Krb5 Client Wait', handler: ->
      {etc_krb5_conf} = @config.krb5
      @wait_connect
        header: 'TCP Admin'
        timeout: -1
        label_true: 'READY'
        servers: for realm, config of etc_krb5_conf.realms
          continue unless config.admin_server
          [host, port] = config.admin_server.split ':'
          host: host
          port: port or 749

## Wait Admin

Wait for the admin interface to be ready by issuing the command `listprincs`.

      @call header: 'Command kadmin', handler: ->
        {etc_krb5_conf} = @config.krb5
        for realm, config of etc_krb5_conf.realms
          continue unless config.kadmin_principal and config.admin_server
          {kadmin_principal, kadmin_password, admin_server} = config
          @wait_execute cmd: misc.kadmin
            timeout: -1
            retry: 5
            label_true: 'READY'
            realm: realm
            kadmin_principal: kadmin_principal
            kadmin_password: kadmin_password
            kadmin_server: admin_server
          , 'listprincs'

## Module Dependencies

    misc = require 'mecano/lib/misc'
