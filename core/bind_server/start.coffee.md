
# Bind server

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Start

Now the service being configured, the "named" service is started.

    exports.push name: 'Bind Server # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'named'
        action: 'start'
      , next
