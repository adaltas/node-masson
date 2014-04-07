---
title: 
layout: module
---

# Telnet

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push name: 'Telnet', callback: (ctx, next) ->
      ctx.service
        name: 'telnet'
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS
