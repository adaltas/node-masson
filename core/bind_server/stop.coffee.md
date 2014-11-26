
# Bind server

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Stop

Now the service being configured, the "named" service is started.

    module.exports.push name: 'Bind Server # Stop', callback: (ctx, next) ->
      ctx.service
        srv_name: 'named'
        action: 'stop'
      , next