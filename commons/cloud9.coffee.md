---
title: 
module: masson/commons/cloud9
layout: module
---

# Cloud9

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/commons/git'
    module.exports.push 'masson/commons/nodejs'

    module.exports.push (ctx) ->
      ctx.config.cloud9 ?= {}
      ctx.config.cloud9.path ?= '/usr/lib/cloud9'
      ctx.config.cloud9.github ?= 'https://github.com/ajaxorg/cloud9.git'
      ctx.config.cloud9.proxy ?= ctx.config.proxy

    module.exports.push (ctx, next) ->
      {proxy} = ctx.config.cloud9
      return next() if proxy
      @name 'Cloud9 # libxml2' 
      @timeout 100000
      ctx.service
        name: 'libxml2-devel'
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

    module.exports.push (ctx, next) ->
      {proxy} = ctx.config.cloud9
      return next() if proxy
      @name 'Cloud9 # SM' 
      @timeout -1
      ctx.execute 
        cmd: 'npm install -g sm'
      , (err, executed) ->
        next err, if executed then ctx.OK else ctx.PASS

    module.exports.push (ctx, next) ->
      {proxy, path, github} = ctx.config.cloud9
      return next() if proxy
      @name 'Cloud9 # Git'
      @timeout -1
      ctx.git
        source: github
        destination: "/usr/lib/#{path}"
      , (err, updated) ->
        next err, if updated then ctx.OK else ctx.PASS

    module.exports.push (ctx, next) ->
      {proxy} = ctx.config.cloud9
      return next() if proxy
      @name 'Cloud9 # Install' 
      @timeout -1
      ctx.execute
        cmd: "sm install"
        cwd: "/usr/lib/cloud9"
      , (err, executed) ->
        next err, ctx.OK
