
# NGINX Web Server Configure

    export default (service) ->
      options = service.options

## Environment

      options.conf_dir ?= '/etc/nginx'
      options.log_dir ?= '/var/log/nginx'
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'

## Identities

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'nginx'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'nginx'
      options.user.gid ?= options.group.name
      options.user.system ?= true
      options.user.comment ?= 'NGINX Web Server User'
      options.user.home ?= '/var/lib/nginx'
      options.user.shell ?= false
