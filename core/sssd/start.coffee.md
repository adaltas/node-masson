
# SSSD Start

    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push name: 'SSSD # Start', handler: (ctx, next) ->
      ctx.service_start
        name: 'sssd'
      .then next
