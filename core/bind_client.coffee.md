
# Bind Client

BIND Utilities is a collection of the client side programs that are included 
with BIND-9.9.3. The BIND package includes the client side programs 
nslookup, dig and host.

    exports = module.exports = []
    exports.push 'masson/core/yum'
    exports.push 'masson/bootstrap'

## Install

The package "bind-utils" is installed.

    exports.push header: 'Bind Client # Install', timeout: -1, handler: ->
      @service
        name: 'bind-utils'
