
# HTTPD Web Server Configure

    module.exports = ->
      httpd = @config.httpd ?= {}
      # Service
      httpd.startup ?= '235'
      httpd.action ?= 'start'
      # User
      httpd.user = name: httpd.user if typeof httpd.user is 'string'
      httpd.user ?= {}
      httpd.user.name ?= 'apache'
      httpd.user.system ?= true
      httpd.user.comment ?= 'Apache HTTPD User'
      httpd.user.home ?= '/var/www'
      httpd.user.shell ?= false
      # Group
      httpd.group = name: httpd.group if typeof httpd.group is 'string'
      httpd.group ?= {}
      httpd.group.name ?= 'apache'
      httpd.group.system ?= true
      httpd.user.gid ?= httpd.group.name
