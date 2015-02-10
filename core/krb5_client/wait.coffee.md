
# Krb5 Client Wait

Wait for all the Kerberos servers referenced by the client configuration.

## Preparation

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push require('./index').configure

## Wait TCP

    exports.push name: 'Krb5 Client # Wait TCP', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      {etc_krb5_conf} = ctx.config.krb5
      default_realm = etc_krb5_conf.libdefaults.default_realm
      servers = for realm, config of etc_krb5_conf.realms
        # continue if default_realm isnt realm
        [host, port] = config.admin_server.split ':'
        host: host, port: port or 749
      ctx.waitIsOpen servers, next

## Wait Admin

Wait for the admin interface to be ready by issuing the command `listprincs`.

    exports.push name: 'Krb5 Client # Wait Admin', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      {etc_krb5_conf} = ctx.config.krb5
      default_realm = etc_krb5_conf.libdefaults.default_realm
      cmds = for realm, config of etc_krb5_conf.realms
        # continue if default_realm isnt realm
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