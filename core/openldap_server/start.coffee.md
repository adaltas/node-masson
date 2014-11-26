
# OpenLDAP Server Start

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Start

    module.exports.push name: 'OpenLDAP Server # Start', callback: (ctx, next) ->
      ctx.service
        srv_name: 'slapd'
        action: 'start'
      , next