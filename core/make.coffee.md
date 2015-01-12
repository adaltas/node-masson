
# Make

Install the GNU make utility to maintain groups of programs.

This action does not use any configuration.

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/yum'

## Package

The package "make" is installed upon execution.

    exports.push name: 'Make # Package', timeout: -1, callback: (ctx, next) ->
      ctx.service
        name: 'make'
      , next
