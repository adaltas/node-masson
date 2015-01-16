
# Telnet

    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push name: 'Telnet', handler: (ctx, next) ->
      ctx.service
        name: 'telnet'
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS
