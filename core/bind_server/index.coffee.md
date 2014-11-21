
# Bind server

Install and configure [named](http://linux.die.net/man/8/named), a 
Domain Name System (DNS) server, part of the BIND 9 distribution f
rom ISC.

    module.exports = []

## Configuration

*   `bind_server.zones` (string|array)   
    A list of zone definition files to be uploaded and registered to the named server.   

See the the "resources section" for additional information.

    module.exports.confiugre = (ctx) ->
      require('./iptables').configure ctx
      ctx.config.bind_server ?= []
      ctx.config.bind_server.zones ?= []
      if typeof ctx.config.bind_server.zones is 'string'
        ctx.config.bind_server.zones = [ctx.config.bind_server.zones]

    module.exports.push commands: 'install', modules: [
      'masson/core/bind_server/install'
      'masson/core/bind_server/start'
    ]

    module.exports.push commands: 'start', modules: 'masson/core/bind_server/start'

    module.exports.push commands: 'stop', modules: 'masson/core/bind_server/stop'


