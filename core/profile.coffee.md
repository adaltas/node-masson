---
title: 
layout: module
---

    each = require 'each'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push name: 'Profile', callback: (ctx, next) ->
      modified = false
      ctx.config.profile ?= {}
      each(ctx.config.profile)
      .parallel(10)
      .on 'item', (filename, content, next) ->
        ctx.write
          destination: "/etc/profile.d/#{filename}"
          content: content
        , (err, written) ->
          modified = true if written
          next err
      .on 'both', (err) ->
        next err, modified
