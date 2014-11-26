---
title: Security
module: masson/core/security
layout: module
---

# Security

This package cover various security related configuration for an operating
system.

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Configuration

*   `selinux` (boolean)   
    Whether SELinux should be activated or not.   
*   `limits` (object)   
    List of files written in "/etc/security/limits.d". Keys are the filename
    and values are the content of the file.

Example:

```json
{
  "security": {
    "selinux": false,
    "limits": {
      "me.conf'": "me - nofile 32768\nme - nproc 65536"
    }
  }
}
```

    module.exports.push (ctx) ->
      ctx.config.security ?= {}
      ctx.config.security.selinux ?= true
      ctx.config.security.limits ?= {}

## SELinux

Security-Enhanced Linux (SELinux) is a mandatory access control (MAC) security 
mechanism implemented in the kernel.

This action update the configuration file present in "/etc/selinux/config".

    module.exports.push name: 'Security # SELinux', callback: (ctx, next) ->
      {selinux} = ctx.config.security
      if selinux
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
        return next err, false if err or not executed
        ctx.execute
          cmd: 'shutdown -r now'
        , (err, executed) ->
          next Error 'Server Reboot after SELINUX changes'

# Limits

On CentOs 6.4, The default values are:

```bash
cat /etc/security/limits.conf
*                -    nofile          8192
cat /etc/security/limits.d/90-nproc.conf
*          soft    nproc     1024
root       soft    nproc     unlimited
```

    module.exports.push name: 'Security # Limits', callback: (ctx, next) ->
      {limits} = ctx.config.security
      writes = for filename, content of limits
        destination: "/etc/security/limits.d/#{filename}"
        content: content
        backup: true
      ctx.write writes, next





