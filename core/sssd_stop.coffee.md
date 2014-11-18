
# SSSD Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push name: 'SSSD # Stop', callback: (ctx, next) ->
      ctx.service
        srv_name: 'sssd'
        action: 'stop'
      , next
