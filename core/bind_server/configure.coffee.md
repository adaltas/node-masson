
# Bind Server Configure

*   `bind_server.user` (string|object)   
    The Unix user name or a user object (see Nikita User documentation).   
*   `bind_server.group` (string|object)   
    The Unix group name or a group object (see Nikita User documentation).   
*   `bind_server.zones` (string|array)   
    A list of zone definition files to be uploaded and registered to the named
    server.   

See the the "resources section" for additional information.

    export default (service) ->
      options = service.options

## Indentities

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'named'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'named'
      options.user.system ?= true
      options.user.gid = options.group.name
      options.user.shell = false
      options.user.comment ?= 'Named'
      options.user.home = '/var/named'

## Configuration

Note, port is not honored by the configuration files but used in iptables and
the network dependencies.

      options.port ?= 53
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'

## Zones

      options.zones ?= []
      if typeof options.zones is 'string'
        options.zones = [options.zones]
