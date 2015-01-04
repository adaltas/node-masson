
# Krb5 Server Wait

Wait for all the Kerberos servers deployed by Masson.

## Preparation

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Wait TCP

    module.exports.push name: 'Krb5 Server # Wait TCP', timeout: -1, callback: (ctx, next) ->
      contexts = ctx.contexts modules: 'masson/core/krb5_server', require('./index').configure
      servers = []
      for context in contexts
        for realm, config of context.config.krb5.kdc_conf.realms
          servers.push host: context.config.host, port: config.kadmind_port or 749
      return next() unless servers.length
      ctx.waitIsOpen servers, next

