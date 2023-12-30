
# HTTPD Web Server Configure

    export default (service) ->
      options = service.options

## Environment

      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      
## Service

      options.startup ?= true
      options.state ?= 'started'

## Identities

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'apache'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'apache'
      options.user.gid ?= options.group.name
      options.user.system ?= true
      options.user.comment ?= 'Apache HTTPD User'
      options.user.home ?= '/var/www'
      options.user.shell ?= false

## Wait

      options.wait_tcp = {}
      options.wait_tcp.fqdn = service.node.fqdn
      options.wait_tcp.port = 80
