
# Bind Server Configure

*   `bind_server.user` (string|object)   
    The Unix user name or a user object (see Mecano User documentation).   
*   `bind_server.group` (string|object)   
    The Unix group name or a group object (see Mecano User documentation).   
*   `bind_server.zones` (string|array)   
    A list of zone definition files to be uploaded and registered to the named
    server.   

See the the "resources section" for additional information.

    module.exports = ->
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
      ctx.config.bind_server.group = name: ctx.config.bind_server.group if typeof ctx.config.bind_server.group is 'string'
      ctx.config.bind_server.group ?= {}
      ctx.config.bind_server.group.name ?= 'named'
      ctx.config.bind_server.group.system ?= true
      # Zones
      ctx.config.bind_server.zones ?= []
      if typeof ctx.config.bind_server.zones is 'string'
        ctx.config.bind_server.zones = [ctx.config.bind_server.zones]
