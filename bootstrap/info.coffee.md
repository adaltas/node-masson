---
title: 
layout: module
---

# Server Info

Gather system information.

    mecano = require 'mecano'
    module.exports = []

    module.exports.push name: 'Bootstrap # Server Info', required: true, callback: (ctx, next) ->
      mecano.exec
        ssh: ctx.ssh
        cmd: 'uname -snrvmo'
        stdout: ctx.log.out
        stderr: ctx.log.err
      , (err, executed, stdout, stderr) ->
        return next err if err
        #Linux hadoop1 2.6.32-279.el6.x86_64 #1 SMP Fri Jun 22 12:19:21 UTC 2012 x86_64 x86_64 x86_64 GNU/Linux
        match = /(\w+) (\w+) ([^ ]+)/.exec stdout
        ctx.kernel_name = match[1]
        ctx.nodename = match[2]
        ctx.kernel_release = match[3]
        ctx.kernel_version = match[4]
        ctx.processor = match[5]
        ctx.operating_system = match[6]
        next null, ctx.PASS