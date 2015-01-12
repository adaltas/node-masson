
# Bind server

Install and configure [named](http://linux.die.net/man/8/named), a 
Domain Name System (DNS) server, part of the BIND 9 distribution f
rom ISC.

    exports = module.exports = []
    exports.push require('../iptables').configure

## Configuration

*   `bind_server.user` (string|object)   
    The Unix user name or a user object (see Mecano User documentation).   
*   `bind_server.group` (string|object)   
    The Unix group name or a group object (see Mecano User documentation).   
*   `bind_server.zones` (string|array)   
    A list of zone definition files to be uploaded and registered to the named
    server.   

See the the "resources section" for additional information.

    module.exports.configure = (ctx) ->
      ctx.config.bind_server ?= {}
      # User
      ctx.config.bind_server.user = name: ctx.config.bind_server.user if typeof ctx.config.bind_server.user is 'string'
      ctx.config.bind_server.user ?= {}
      ctx.config.bind_server.user.name ?= 'named'
      ctx.config.bind_server.user.system ?= true
      ctx.config.bind_server.user.gid = 'named'
      ctx.config.bind_server.user.shell = false
      ctx.config.bind_server.user.comment ?= 'Named'
      ctx.config.bind_server.user.home = '/var/named'
      # Group
      ctx.config.bind_server.group = name: ctx.config.ryba.bind_server if typeof ctx.config.ryba.bind_server is 'string'
      ctx.config.bind_server.group ?= {}
      ctx.config.bind_server.group.name ?= 'named'
      ctx.config.bind_server.group.system ?= true
      # Zones
      ctx.config.bind_server.zones ?= []
      if typeof ctx.config.bind_server.zones is 'string'
        ctx.config.bind_server.zones = [ctx.config.bind_server.zones]

    exports.push commands: 'install', modules: [
      'masson/core/bind_server/install'
      'masson/core/bind_server/start'
    ]

    exports.push commands: 'start', modules: 'masson/core/bind_server/start'

    exports.push commands: 'stop', modules: 'masson/core/bind_server/stop'


