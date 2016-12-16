
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
    collect = require '../lib/collect'
    multimatch = require '../../lib/multimatch'
    params = require '../../lib/params'
    bootstrap = require '../lib/bootstrap'

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
    "bootstrap.private_key_location".   
*   `private_key_location` (string)   
    Path where to read the private key for Ryba, default to "~/.ssh/id_rsa".   
*   `public_key` (string)   
    Public key associated with the private key.   
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

    # module.exports = header: 'Bootstrap Connection', required: true, timeout: -1, handler: (options, next) ->
    module.exports = ->
      # return if @params.hosts? and (multimatch( @config.host, @params.hosts)).length is 0
      return if @params.command in ['configure', 'prepare']
      connection = @config.connection ?= {}
      connection.username ?= 'root'
      connection.host ?= connection.ip or @config.ip or @config.host
      connection.port ?= 22
      connection.private_key ?= null
      connection.private_key_location ?= '~/.ssh/id_rsa'
      # connection.public_key ?= []
      # connection.public_key = [connection.public_key] if typeof connection.public_key is 'string'
      connection.retry = 3
      connection.end ?= true # End the connection when the run is finish
      connection.wait ?= 1000
      connection.bootstrap ?= {}
      connection.bootstrap.host ?= connection.ip or connection.host
      connection.bootstrap.port ?= connection.port
      connection.bootstrap.cmd ?= 'su -'
      connection.bootstrap.username ?= null
      connection.bootstrap.password ?= null
      connection.bootstrap.retry = 3

      @call header: 'Connection', irreversible: true, (options, next) ->
        close = -> @options.ssh?.end() if connection.end
        @on 'error', close
        @on 'end', close
        attempts = 0
        has_rebooted = false
        modified = false
        do_private_key = =>
          return do_connect() if connection.private_key
          # options.log "Read private key file: #{connection.private_key_location}"
          misc.path.normalize connection.private_key_location, (location) =>
            fs.readFile location, 'ascii', (err, content) =>
              return next Error "Private key doesnt exists: #{JSON.stringify location}" if err and err.code is 'ENOENT'
              return next err if err
              connection.private_key = content
              do_connect()
        do_connect = =>
          # options.log "Connect with private key"
          config = misc.merge {}, @config.connection
          connect config, (err, connection) =>
            return do_bootstrap() if err
            # options.log "SSH connected"
            @options.ssh = connection
            next null, false
        do_bootstrap = =>
          # options.log "Connection failed, bootstrap"
          bootstrap.call @, options, (err, reboot) =>
            return next err if err
            if reboot then do_wait_reboot() else do_connect_after_bootstrap()
        do_wait_reboot = =>
          # options.log 'Wait for reboot'
          config = misc.merge {}, @config.connection,
            retry: 3
          connect config, (err, conn) =>
            return do_connect_after_bootstrap() if err
            conn.end()
            conn.on 'error', do_wait_reboot
            conn.on 'end', do_wait_reboot
        do_connect_after_bootstrap = =>
          # options.log 'Connect when rebooted'
          config = misc.merge {}, @config.connection,
            retry: true
          connect config, (err, conn) =>
            return next err if err
            # options.log "SSH connected"
            @options.ssh = conn
            next null, true
        do_private_key()
      null
