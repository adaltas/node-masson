---
title: Connection
module: masson/bootstrap/connection
layout: module
---

# Connection

Prepare the system to receive password-less root login and 
initialize an SSH connection. Additionnally, it disable SELINUX which require a 
restart. The restart is handle by Masson and the installation procedure will
continue as soon as an SSH connection is again available.

    fs = require 'fs'
    {exec} = require 'child_process'
    misc = require 'mecano/lib/misc'
    connect = require 'ssh2-exec/lib/connect'
    collect = require './lib/collect'
    bootstrap = require './lib/bootstrap'
    module.exports = []
    module.exports.push 'masson/bootstrap/log'

## Configuration

The goal of the bootstrap configuration is to provide a way to gain superuser
access to the remote server. There are a few ways to achieve it. You should 
declare a "bootstrap.public_key" property. If it matches you're local private key
found at "~/.ssh/id_rsa", if it is deployed on the remote server for 
the root user (commonly found inside the "/root/.ssh/authorized_keys" file) and 
if the remote server is ready to accept root SSH connections (the 
"PermitRootLogin" property inside the "/etc/ssh/sshd_config" configuration 
file), then there nothing else to configuration. Otherwise, the server will be
prepared to do so. You must declare a super user with sudo permissions using 
the "username" and "password" properties. The script will use those credentials
to loggin and will try to become root with the "su -" command. Use the "cmd" 
property if you must use a different command (such as "sudo su -").

Options include:

*   `cmd` (string)   
    Command used to become the root user on the remote server, default to "su -".   
*   `public_key` (array|string)   
    List of public keys to be written on the remote root "authorized_keys" file.   
*   `password` (string)   
    Password of the user with super user permissions, required if current user 
    running masson doesnt yet have remote access as root.   
*   `username` (string)   
    Username of the user with super user permissions, required if current user 
    running masson doesnt yet have remote access as root.   

Example:

```json
{
  "bootstrap": {
    "username": "vagrant",
    "password": "vagrant",
    "cmd": "sudo su -",
    "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAuYziVgwFAXvExxIj5HgAywFeSfu9zxoLc5bCdeJhS/gh4EtpMN0McHd21M4btuopMAL/sctT4+SiBqwOIERw0rGWrat4WE2qBReEc+6hvdoiUx+7WglDCYePbV91N+x421UYzHhNPUg62jXIfg+o5zG/tdEDbpBAq2EX3vRsncenlhB+p/LsSkY+2+tBJLW172BN1ncKjImFglMwW+7OxGP2U9LoMMFyUs1zS65p8WgHHi/+6ZNsP0wIhKPPl8BiFJ6dLiNjlRuXLX9fGcQDJGrlYbad5Thb5wpQe1EZCF9qBloUkdj7aTIu+dainTP/I87Eo2Y47KsSydvopjqceQ== david@adaltas.com"
  }
}
```

    module.exports.push (ctx) ->
      ctx.config.bootstrap ?= {}
      ctx.config.bootstrap.host ?= if ctx.config.ip then ctx.config.ip else ctx.config.host
      ctx.config.bootstrap.port ?= ctx.config.port or 22
      ctx.config.bootstrap.public_key ?= []
      ctx.config.bootstrap.public_key = [ctx.config.bootstrap.public_key] if typeof ctx.config.bootstrap.public_key is 'string'
      ctx.config.bootstrap.cmd ?= 'su -'

## Connection

Masson need to connect over ssh as root and, for this, it can prepare
its own private key by declaring the "bootstrap.private_key" option.
However, it is important in such circumstances that we guarantee no
existing key would be overwritten.

    module.exports.push name: 'Bootstrap # Connection', required: true, timeout: -1, callback: (ctx, next) ->
      {private_key} = ctx.config.bootstrap
      close = -> ctx.ssh?.end()
      ctx.run.on 'error', close
      ctx.run.on 'end', close
      attempts = 0
      has_rebooted = false
      modified = false
      do_private_key = ->
        return do_ssh() unless private_key
        ctx.log "Place SSH private key inside \"~/.ssh\""
        # Handle tilde
        misc.path.normalize '~/.ssh/id_rsa', (id_rsa) ->
          fs.readFile id_rsa, 'ascii', (err, content) ->
            return next Error err if err and err.code isnt 'ENOENT'
            return next Error "Could not overwritte existing key" if not err and content.trim() isnt private_key.trim()
            return do_ssh() if content is private_key
            exec """
            mkdir -p ~/.ssh
            chmod 700 ~/.ssh
            echo '#{private_key}' > ~/.ssh/id_rsa
            chmod 600 ~/.ssh/id_rsa
            """, (err, stdout, stderr) ->
              return next err if err
              do_ssh()
      do_ssh = ->
        attempts++
        ctx.log "SSH login #{attempts} to root@#{ctx.config.host}"
        config = misc.merge {}, ctx.config.bootstrap,
          host: ctx.config.ip or ctx.config.host
          private_key: null # make sure "bootstap.private_key" isnt used by ssh2
          username: 'root'
          password: null
          readyTimeout: 120 * 1000 # default to 10s, now 2mn
        connect config, (err, connection) ->
          # First attempt failed, we go collecting bootstrap information on err
          return do_collect() if err and attempts is 1
          # Once we are sure the server went for reboot, we wait for a new connection
          if has_rebooted and err and (['ETIMEDOUT', 'ECONNREFUSED', 'EHOSTUNREACH'].indexOf(err.code) isnt -1)
            ctx.log 'Wait for reboot'
            console.log 'wait for reboot'
            return setTimeout do_ssh, 10
          # We detect a reboot
          if attempts isnt 1 and not has_rebooted 
            has_rebooted = true if err
            console.log 'has_rebooted', has_rebooted
            return setTimeout do_ssh, 10
          return next err if err
          ctx.log "SSH connected"
          ctx.ssh = connection
          next null, if modified then ctx.OK else ctx.PASS
      do_collect = ->
        modified = true
        ctx.log 'Collect login information'
        collect ctx.config.bootstrap, (err) ->
          return next err if err
          do_boot()
      do_boot = ->
        ctx.log 'Deploy ssh key'
        bootstrap ctx, (err) ->
          return next err if err
          ctx.log 'Reboot and login'
          do_ssh()
      do_private_key()


