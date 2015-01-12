
    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push name: 'Network # restart', timeout: -1, callback: (ctx, next) ->
      ctx.execute
        cmd: 'service network restart'
      , next
