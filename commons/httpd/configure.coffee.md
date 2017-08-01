
# HTTPD Web Server Configure

    module.exports = ->
      options = @config.httpd ?= {}
      # Service
      options.startup ?= '235'
      options.action ?= 'start'
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'apache'
      options.user.system ?= true
      options.user.comment ?= 'Apache HTTPD User'
      options.user.home ?= '/var/www'
      options.user.shell ?= false
      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'apache'
      options.group.system ?= true
      options.user.gid ?= options.group.name
