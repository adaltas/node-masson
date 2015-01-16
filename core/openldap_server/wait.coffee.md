
# OpenLDAP Server Wait

Wait for all the OpenLDAP servers deployed by Masson.

## Preparation

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Wait TCP

    exports.push name: 'OpenLDAP Server # Wait TCP', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      contexts = ctx.contexts modules: 'masson/core/openldap_server', require('./index').configure
      servers = for context in contexts
        port = if context.config.openldap_server.tls then 389 else 636
        host: context.config.host, port: port
      ctx.waitIsOpen servers, next

