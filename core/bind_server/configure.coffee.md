
# Bind Server Configure

*   `bind_server.user` (string|object)   
    The Unix user name or a user object (see Nikita User documentation).   
*   `bind_server.group` (string|object)   
    The Unix group name or a group object (see Nikita User documentation).   
*   `bind_server.zones` (string|array)   
    A list of zone definition files to be uploaded and registered to the named
    server.   

See the the "resources section" for additional information.

    module.exports = ->
      @config.bind_server ?= {}
      # User
      @config.bind_server.user = name: @config.bind_server.user if typeof @config.bind_server.user is 'string'
      @config.bind_server.user ?= {}
      @config.bind_server.user.name ?= 'named'
      @config.bind_server.user.system ?= true
      @config.bind_server.user.gid = 'named'
      @config.bind_server.user.shell = false
      @config.bind_server.user.comment ?= 'Named'
      @config.bind_server.user.home = '/var/named'
      # Group
      @config.bind_server.group = name: @config.bind_server.group if typeof @config.bind_server.group is 'string'
      @config.bind_server.group ?= {}
      @config.bind_server.group.name ?= 'named'
      @config.bind_server.group.system ?= true
      # Zones
      @config.bind_server.zones ?= []
      if typeof @config.bind_server.zones is 'string'
        @config.bind_server.zones = [@config.bind_server.zones]
