
# OpenLDAP Server Start

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Stop

    module.exports.push name: 'OpenLDAP Server # Stop', callback: (ctx, next) ->
      ctx.service
        srv_name: 'slapd'
        action: 'stop'
      , next