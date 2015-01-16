
# Telnet

    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push name: 'Telnet', handler: (ctx, next) ->
      ctx.service
        name: 'telnet'
      , next
