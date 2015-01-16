
# Tree

    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push name: 'Tree', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'tree'
      , next
