
# Krb5 Client Wait

Wait for 

## Preparation

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Wait

    module.exports.push name: 'Krb5 Client # Wait', timeout: -1, callback: (ctx, next) ->
      # {etc_krb5_conf} = ctx.config.krb5
      cmds = for realm, config of ctx.config.krb5.etc_krb5_conf.realms
        {kadmin_principal, kadmin_password, admin_server} = config
        misc.kadmin
          realm: realm
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server
        , 'listprincs'
      ctx.waitForExecution cmds, (err) -> next err
      # each(etc_krb5_conf.realms)
      # .on 'item', (realm, config, next) ->
      #   {kadmin_principal, kadmin_password, admin_server} = config
      #   cmd = misc.kadmin
      #     realm: realm
      #     kadmin_principal: kadmin_principal
      #     kadmin_password: kadmin_password
      #     kadmin_server: admin_server
      #   , 'listprincs'
      #   ctx.waitForExecution cmd, (err) ->
      #     next err
      # .on 'both', (err) ->
      #   next err

## Module Dependencies

    each = require 'each'
    misc = require 'mecano/lib/misc'