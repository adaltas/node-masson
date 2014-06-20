---
title: 
layout: module
---

# HTTPD web server

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Configuration

Configure the HTTPD server.

    module.exports.push (ctx) ->
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

## Users & Groups

By default, the "httpd" package create the following entries:

```bash
cat /etc/passwd | grep pig
apache:x:48:48:Apache HTTPD User:/var/www:/sbin/nologin
cat /etc/group | grep hadoop
apache:x:48:
```

    module.exports.push name: 'HTTPD # Users & Groups', callback: (ctx, next) ->
      {group, user} = ctx.config.httpd
      ctx.group group, (err, gmodified) ->
        return next err if err
        ctx.user user, (err, umodified) ->
          next err, if gmodified or umodified then ctx.OK else ctx.PASS

## Install

Install the HTTPD service and declare it as a startup service.

    module.exports.push name: 'HTTPD # Install', timeout: -1, callback: (ctx, next) ->
      {startup, action} = ctx.config.httpd
      ctx.service
        name: 'httpd'
        startup: startup
        action: action
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS


