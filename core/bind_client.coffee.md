
# Bind Client

BIND Utilities is a collection of the client side programs that are included 
with BIND-9.9.3. The BIND package includes the client side programs 
nslookup, dig and host.

## Install

The package "bind-utils" is installed.

    export default header: 'Bind Client Install', handler: ->
      @service
        name: 'bind-utils'
