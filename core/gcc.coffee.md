
# GCC

GNU project C and C++ compiler.

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/yum'

## Install

The package "gcc-c++" is installed.

    exports.push name: 'GCC # Install', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'gcc-c++'
      , next
