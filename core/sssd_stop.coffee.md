
# SSSD Stop

    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push name: 'SSSD # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'sssd'
        action: 'stop'
      , next
