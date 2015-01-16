
# Bind Client

BIND Utilities is a collection of the client side programs that are included 
with BIND-9.9.3. The BIND package includes the client side programs 
nslookup, dig and host.

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/yum'

## Install

The package "bind-utils" is installed.

    exports.push name: 'Bind Client # Install', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'bind-utils'
      , next
