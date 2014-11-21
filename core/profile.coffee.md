---
title: 
layout: module
---

    each = require 'each'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push name: 'Profile', callback: (ctx, next) ->
      ctx.config.profile ?= {}
      writes = for filename, content of ctx.config.profile
        destination: "/etc/profile.d/#{filename}"
        content: content
      ctx.write writes, next
