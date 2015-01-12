
# Bind server

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Start

Now the service being configured, the "named" service is started.

    exports.push name: 'Bind Server # Start', callback: (ctx, next) ->
      ctx.service
        srv_name: 'named'
        action: 'start'
      , next