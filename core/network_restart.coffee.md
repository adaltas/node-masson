
    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Network # restart', timeout: -1, callback: (ctx, next) ->
      ctx.execute
        cmd: 'service network restart'
      , next
