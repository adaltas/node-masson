

# Docker Server

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push name: 'Install', callback: (ctx, next) ->
      ctx.service
        name: 'docker-io'
        chk_name: 'docker'
        startup: true
        action: 'start'
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS
