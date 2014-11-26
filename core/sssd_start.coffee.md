
# SSSD Start

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'SSSD # Start', callback: (ctx, next) ->
      ctx.service
        srv_name: 'sssd'
        action: 'start'
      , next
