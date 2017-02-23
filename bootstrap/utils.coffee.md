
# Bootstrap Utils

The `utils` module enriches the bootstraping process with commonly used functions.

    exports = module.exports = []
    exports.push header: 'Bootstrap Utils', required: true, handler: ->

## Reboot

`ctx.reboot(callback)`

Reboot the current server and call the user provided callback when the startup
process is finished.

      @reboot = (callback) ->
        attempts = 0
        wait = =>
          # @log 'Wait for reboot'
          return setTimeout ssh, 2000
        ssh = =>
          attempts++
          # @log "SSH login attempt: #{attempts}"
          config = misc.merge {}, @config.bootstrap,
            username: 'root'
            password: null
          connect config, (err, connection) ->
            if err and (err.code is 'ETIMEDOUT' or err.code is 'ECONNREFUSED')
              return wait()
            return callback err if err
            @ssh = connection
            callback()
        # @log "Reboot"
        @system.execute
          cmd: 'reboot\n'
        , (err, executed, stdout, stderr) ->
          return callback err if err
          wait()

## SSH connection

Open an SSH connection to a remote server. The connection is cached inside the 
current server context until the context is destroyed.   

Options include:   

*   `config`   
    SSH object configuration with all the properties supported by [ssh2] and
    [ssh2-exec/lib/connect][exec].   

Example login to "master1.hadoop" as "root" and the private key present inside 
"~/.ssh/id_rsa":

```coffee
ctx.connect username: root, host: "master1.hadoop", (err, ssh) ->
  console.log 'connected' unless err
```

      @connect = (config, callback) =>
        return callback null, @ssh unless config?
        @connections ?= {}
        if typeof config is 'string'
          destctx = @hosts[config]
          require('./connection').configure destctx
          config = destctx.config.connection
        # @log "SSH connection to #{config.host}"
        # Connection already created, use it
        return callback null, @connections[config.host] if @connections[config.host]
        do_private_key = =>
          return do_connect() if config.private_key
          # @log "Read private key file: #{config.private_key_location}"
          misc.path.normalize config.private_key_location, (location) ->
            fs.readFile location, 'ascii', (err, content) ->
              return next Error "Private key doesnt exists: #{JSON.encode location}" if err and err.code is 'ENOENT'
              return next err if err
              config.private_key = content
              do_connect()
        do_connect = =>
          # config.privateKey = config.private_key
          connect config, (err, connection) =>
            return callback err if err
            # @log "SSH connection open"
            @connections[config.host] = connection
            close = (err) ->
              # @log "SSH connection closed for #{config.host}"
              # @log "Error closing connection: #{err.stack or err.message}" if err
              connection.end()
            @on 'error', close
            @on 'end', close
            callback null, connection
        do_private_key()

## Modules Dependencies

    fs = require 'fs'
    misc = require 'mecano/lib/misc'
    connect = require 'ssh2-connect'

[ssh2]: https://github.com/mscdex/ssh2
[exec]: https://github.com/wdavidw/node-ssh2-exec/blob/master/src/connect.coffee.md
