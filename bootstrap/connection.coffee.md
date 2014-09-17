---
title: Connection
module: masson/bootstrap/connection
layout: module
---

# Bootstrap Connection

Prepare the system to receive password-less root login and 
initialize an SSH connection. Additionnally, it disable SELINUX which require a 
restart. The restart is handle by Masson and the installation procedure will
continue as soon as an SSH connection is again available.

    fs = require 'fs'
    # path = require 'path'
    {exec} = require 'child_process'
    misc = require 'mecano/lib/misc'
    connect = require 'ssh2-connect'
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
file), then there nothing else to configure. Otherwise, the server will be
prepared to do so. You must declare a super user with sudo permissions using 
the "username" and "password" properties. The script will use those credentials
to loggin and will try to become root with the "su -" command. Use the "cmd" 
property if you must use a different command (such as "sudo su -").

Options include:

*   `cmd` (string)   
    Command used to become the root user on the remote server, default to "su -".   
*   `private_key` (string)   
    Private key for Ryba, optional, default to the value defined by
    "bootstrap.privateKey_location".   
*   `private_key_location` (string)   
    Path where to read the private key for Ryba, default to "~/.ssh/id_rsa".   
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

    module.exports.push required: true, callback: (ctx) ->
      ctx.config.connection ?= {}
      ctx.config.connection.username ?= 'root'
      ctx.config.connection.host ?= if ctx.config.ip then ctx.config.ip else ctx.config.host
      ctx.config.connection.port ?= ctx.config.port or 22
      ctx.config.connection.private_key ?= null
      ctx.config.connection.private_key_location ?= '~/.ssh/id_rsa'
      ctx.config.connection.public_key ?= []
      ctx.config.connection.public_key = [ctx.config.connection.public_key] if typeof ctx.config.connection.public_key is 'string'
      ctx.config.connection.retry = 3
      ctx.config.connection.wait = 1000
      ctx.config.connection.bootstrap ?= {}
      ctx.config.connection.bootstrap.host ?= if ctx.config.ip then ctx.config.ip else ctx.config.host
      ctx.config.connection.bootstrap.cmd ?= 'su -'
      ctx.config.connection.bootstrap.username ?= null
      ctx.config.connection.bootstrap.password ?= null
      ctx.config.connection.bootstrap.retry = 3

## Connection

Masson need to connect over ssh as root and, for this, it can prepare
its own private key by declaring the "bootstrap.private_key" option.
However, it is important in such circumstances that we guarantee no
existing key would be overwritten.

    module.exports.push name: 'Bootstrap # Connection', required: true, timeout: -1, callback: (ctx, next) ->
      {private_key, private_key_location} = ctx.config.connection
      close = -> ctx.ssh?.end()
      # ctx.run.on 'error', close
      # ctx.run.on 'end', close
      ctx.on 'error', close
      ctx.on 'end', close
      attempts = 0
      has_rebooted = false
      modified = false
      do_private_key = ->
        return do_connect() if private_key
        ctx.log "Read private key file: #{private_key_location}"
        misc.path.normalize private_key_location, (location) ->
          fs.readFile location, 'ascii', (err, content) ->
            return next Error "Private key doesnt exists: #{JSON.encode location}" if err and err.code is 'ENOENT'
            return next err if err
            ctx.config.connection.private_key = content
            do_connect()
      do_connect = ->
        ctx.log "Connect with private key"
        config = misc.merge {}, ctx.config.connection,
          privateKey: ctx.config.connection.private_key
        connect config, (err, connection) ->
          return do_bootstrap() if err
          ctx.log "SSH connected"
          ctx.ssh = connection
          next null, ctx.PASS
      do_bootstrap = ->
        ctx.log "Connection failed, bootstrap"
        bootstrap ctx, (err) ->
          return next err if err
          do_wait_reboot()
      do_wait_reboot = ->
        ctx.log 'Wait for reboot'
        config = misc.merge {}, ctx.config.connection,
          privateKey: ctx.config.connection.private_key
          retry: 3
        connect config, (err, conn) ->
          return do_connect_after_bootstrap() if err
          conn.end()
          conn.on 'error', do_wait_reboot
          conn.on 'end', do_wait_reboot
      do_connect_after_bootstrap = ->
        ctx.log 'Connect when rebooted'
        config = misc.merge {}, ctx.config.connection,
          privateKey: ctx.config.connection.private_key
          retry: true
        connect config, (err, conn) ->
          return next err if err
          ctx.log "SSH connected"
          ctx.ssh = conn
          next null, ctx.OK
      do_private_key()


