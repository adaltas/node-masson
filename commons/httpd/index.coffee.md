
# HTTPD Web Server

    exports = module.exports = []

## Configuration

Configure the HTTPD server.

    exports.push (ctx) ->
      require('../../core/iptables').configure ctx
      ctx.config.httpd ?= {}
      # Service
      ctx.config.httpd.startup ?= '235'
      ctx.config.httpd.action ?= 'start'
      # User
      ctx.config.httpd.user = name: ctx.config.httpd.user if typeof ctx.config.httpd.user is 'string'
      ctx.config.httpd.user ?= {}
      ctx.config.httpd.user.name ?= 'apache'
      ctx.config.httpd.user.system ?= true
      ctx.config.httpd.user.gid ?= 'apache'
      ctx.config.httpd.user.comment ?= 'Apache HTTPD User'
      ctx.config.httpd.user.home ?= '/var/www'
      ctx.config.httpd.user.shell ?= false
      # Group
      ctx.config.httpd.group = name: ctx.config.httpd.group if typeof ctx.config.httpd.group is 'string'
      ctx.config.httpd.group ?= {}
      ctx.config.httpd.group.name ?= 'apache'
      ctx.config.httpd.group.system ?= true

    exports.push commands: 'check', modules: 'masson/commons/httpd/check'

    exports.push commands: 'install', modules: [
      'masson/commons/httpd/install'
      'masson/commons/httpd/start'
    ]

    # exports.push commands: 'reload', modules: 'masson/commons/httpd/install'

    exports.push commands: 'start', modules: 'masson/commons/httpd/start'

    exports.push commands: 'status', modules: 'masson/commons/httpd/status'

    exports.push commands: 'stop', modules: 'masson/commons/httpd/stop'



