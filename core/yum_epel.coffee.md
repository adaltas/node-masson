---
title: 
layout: module
---

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/curl'

    module.exports.push (ctx) ->
      require('./yum').configure ctx
      ctx.config.yum.epel ?= true
      ctx.config.yum.epel_url = 'http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm'

    module.exports.push name: 'YUM # Epel', timeout: 100000, callback: (ctx, next) ->
      {epel, epel_url} = ctx.config.yum
      return next() unless epel
      ctx.execute
        cmd: "rpm -Uvh #{epel_url}"
        code_skipped: 1
      , (err, executed) ->
        next err, if executed then ctx.OK else ctx.PASS
