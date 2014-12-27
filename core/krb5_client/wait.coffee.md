
# Krb5 Client Wait

Wait for all the Kerberos servers referenced by the client configuration.

## Preparation

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Wait TCP

    module.exports.push name: 'Krb5 Client # Wait TCP', timeout: -1, callback: (ctx, next) ->
      {etc_krb5_conf} = ctx.config.krb5
      default_realm = etc_krb5_conf.libdefaults.default_realm
      servers = for realm, config of etc_krb5_conf.realms
        # continue if default_realm isnt realm
        [host, port] = config.admin_server.split ':'
        host: host, port: port or 749
      ctx.waitIsOpen servers, (err) -> next err

## Wait `listprincs`

    module.exports.push name: 'Krb5 Client # Wait `listprincs`', timeout: -1, callback: (ctx, next) ->
      {etc_krb5_conf} = ctx.config.krb5
      default_realm = etc_krb5_conf.libdefaults.default_realm
      cmds = for realm, config of etc_krb5_conf.realms
        # continue if default_realm isnt realm
        {kadmin_principal, kadmin_password, admin_server} = config
        misc.kadmin
          realm: realm
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server
        , 'listprincs'
      ctx.waitForExecution cmds, (err) -> next err

## Module Dependencies

    misc = require 'mecano/lib/misc'