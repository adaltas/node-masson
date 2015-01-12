
# OpenLDAP Server Start

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Stop

    exports.push name: 'OpenLDAP Server # Stop', callback: (ctx, next) ->
      ctx.service
        srv_name: 'slapd'
        action: 'stop'
      , next