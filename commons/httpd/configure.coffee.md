
# HTTPD Web Server Configure

    module.exports = handler: ->
      @config.httpd ?= {}
      # Service
      @config.httpd.startup ?= '235'
      @config.httpd.action ?= 'start'
      # User
      @config.httpd.user = name: @config.httpd.user if typeof @config.httpd.user is 'string'
      @config.httpd.user ?= {}
      @config.httpd.user.name ?= 'apache'
      @config.httpd.user.system ?= true
      @config.httpd.user.gid ?= 'apache'
      @config.httpd.user.comment ?= 'Apache HTTPD User'
      @config.httpd.user.home ?= '/var/www'
      @config.httpd.user.shell ?= false
      # Group
      @config.httpd.group = name: @config.httpd.group if typeof @config.httpd.group is 'string'
      @config.httpd.group ?= {}
      @config.httpd.group.name ?= 'apache'
      @config.httpd.group.system ?= true
