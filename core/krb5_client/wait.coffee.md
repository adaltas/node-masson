
# Krb5 Client Wait

Wait for all the Kerberos servers referenced by the client configuration.

## Preparation

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push require('./index').configure

## Wait TCP

    exports.push name: 'Krb5 Client # Wait admin TCP', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      {etc_krb5_conf} = ctx.config.krb5
      ctx.wait_connect
        servers: for realm, config of etc_krb5_conf.realms
          continue unless config.kadmin_principal
          [host, port] = config.admin_server.split ':'
          host: host
          port: port or 749
      .then next

## Wait Admin

Wait for the admin interface to be ready by issuing the command `listprincs`.

    exports.push name: 'Krb5 Client # Wait Admin', retry: 5, timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      {etc_krb5_conf} = ctx.config.krb5
      cmds = for realm, config of etc_krb5_conf.realms
        continue unless config.kadmin_principal
        {kadmin_principal, kadmin_password, admin_server} = config
        continue unless kadmin_principal
        misc.kadmin
          realm: realm
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server
        , 'listprincs'
      ctx.waitForExecution cmds, next

## Module Dependencies

    misc = require 'mecano/lib/misc'
    each = require 'each'


