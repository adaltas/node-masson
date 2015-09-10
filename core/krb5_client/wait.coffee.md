
# Krb5 Client Wait

Wait for all the Kerberos servers referenced by the client configuration.

## Preparation

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    # exports.push require('./index').configure

## Wait TCP

    exports.push name: 'Krb5 Client # Wait admin TCP', timeout: -1, label_true: 'READY', handler: ->
      {etc_krb5_conf} = @config.krb5
      @wait_connect
        servers: for realm, config of etc_krb5_conf.realms
          continue unless config.kadmin_principal
          [host, port] = config.admin_server.split ':'
          host: host
          port: port or 749

## Wait Admin

Wait for the admin interface to be ready by issuing the command `listprincs`.

    exports.push name: 'Krb5 Client # Wait Admin', retry: 5, timeout: -1, label_true: 'READY', handler: ->
      {etc_krb5_conf} = @config.krb5
      for realm, config of etc_krb5_conf.realms
        continue unless config.kadmin_principal
        {kadmin_principal, kadmin_password, admin_server} = config
        continue unless kadmin_principal
        @wait_execute cmd: misc.kadmin
          realm: realm
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server
        , 'listprincs'

## Module Dependencies

    misc = require 'mecano/lib/misc'
    each = require 'each'
