
# SSSD Start

    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push name: 'SSSD # Start', callback: (ctx, next) ->
      ctx.service
        srv_name: 'sssd'
        action: 'start'
      , next
