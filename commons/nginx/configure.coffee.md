
# NGINX Web Server Configure

    module.exports = ->
      options = @config.nginx ?= {}
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'nginx'
      options.user.system ?= true
      options.user.comment ?= 'NGINX Web Server User'
      options.user.home ?= '/var/lib/nginx'
      options.user.shell ?= false
      options.conf_dir ?= '/etc/nginx'
      options.log_dir ?= '/var/log/nginx'
      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'nginx'
      options.group.system ?= true
      options.user.gid ?= options.group.name
