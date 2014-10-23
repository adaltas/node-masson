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

    module.exports.push name: 'Cloud9 # libxml2', callback: (ctx, next) ->
      {proxy} = ctx.config.cloud9
      return next() if proxy
      ctx.service
        name: 'libxml2-devel'
      , next

    module.exports.push name: 'Cloud9 # SM', callback: (ctx, next) ->
      {proxy} = ctx.config.cloud9
      return next() if proxy
      ctx.execute
        cmd: 'npm install -g sm'
      , next

    module.exports.push name: 'Cloud9 # Git', callback: (ctx, next) ->
      {proxy, path, github} = ctx.config.cloud9
      return next() if proxy
      ctx.git
        source: github
        destination: "/usr/lib/#{path}"
      , next

    module.exports.push name: 'Cloud9 # Install', callback: (ctx, next) ->
      {proxy} = ctx.config.cloud9
      return next() if proxy
      # TODO: detect previous install of sm
      ctx.execute
        cmd: "sm install"
        cwd: "/usr/lib/cloud9"
      , next


