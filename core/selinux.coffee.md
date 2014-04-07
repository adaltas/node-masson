---
title: 
layout: module
---

# SELinux

Security-Enhanced Linux (SELinux) is a mandatory access control (MAC) security mechanism implemented in the kernel.

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Configuration

Configuration is available through the "selinux" 
which expect a boolean value to activate or disable selinux.

    module.exports.push (ctx, next) ->
      ctx.config.selinux ?= true
      ctx.config.restart_msg ?= 'SELINUX changed, server restarting, re-execute this command later'
      next()

## Configure

Update the configuration file present in "/etc/selinux/config".

    module.exports.push name: 'SELinux # Configure', callback: (ctx, next) ->
      if ctx.config.selinux
        from = 'disabled'
        to = 'enforcing'
      else
        from = 'enforcing'
        to = 'disabled'
      ctx.write
        destination: '/etc/selinux/config'
        match: /^SELINUX=.*/mg
        replace: "SELINUX=#{to}"
      , (err, executed) ->
        return next err if err
        return next null, ctx.PASS unless executed
        ctx.execute
          cmd: 'shutdown -r now'
        , (err, executed) ->
          next err, ctx.STOP, ctx.config.restart_msg










