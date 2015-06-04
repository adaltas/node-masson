
# Bootstrap Utils

The `utils` module enriches the bootstraping process with commonly used functions.

    fs = require 'fs'
    each = require 'each'
    misc = require 'mecano/lib/misc'
    connect = require 'ssh2-connect'
    exports = module.exports = []
    exports.push name: 'Bootstrap # Utils', required: true, handler: (ctx) ->

## Reboot

`ctx.reboot(callback)`

Reboot the current server and call the user provided callback when the startup
process is finished.

      ctx.reboot = (callback) ->
        attempts = 0
        wait = ->
          ctx.log 'Wait for reboot'
          return setTimeout ssh, 2000
        ssh = ->
          attempts++
          ctx.log "SSH login attempt: #{attempts}"
          config = misc.merge {}, ctx.config.bootstrap,
            username: 'root'
            password: null
          connect config, (err, connection) ->
            if err and (err.code is 'ETIMEDOUT' or err.code is 'ECONNREFUSED')
              return wait()
            return callback err if err
            ctx.ssh = connection
            callback()
        ctx.log "Reboot"
        ctx.execute
          cmd: 'reboot\n'
        , (err, executed, stdout, stderr) ->
          return callback err if err
          wait()

## Wait for process execution

The command is provided as a string:   
`ctx.waitForExecution(cmd, [options], callback)`   

The command is associated to the `cmd` property of the `options` object:   
`ctx.waitForExecution(options, callback)`

Run a command periodically and call the user provided callback once it returns 
the expected status code.

Emitted event:

*   `wait`   
    Send when we enter this function and before we first try to issue the command.   
*   `waited`   
    Send once the command succeed and when we are ready to call the user 
    callback.   

Options include:   

*   `cmd` (string|array)   
    The command to be executed.    
*   `interval`   
    Time interval between which we should wait before re-executing the command, default to 2s.   
*   `code`   
    Expected exit code to recieve to exit and call the user callback, default to "0".   
*   `code_skipped`   
    Expected code to be returned when the command failed and should be 
    scheduled for later execution, default to "1".   

Example:

```coffee
ctx.waitForExecution cmd: "test -f /tmp/sth", (err) ->
  # file is created, ready to continue
``` 

      ctx.waitForExecution = () ->
        if typeof arguments[0] is 'string' or Array.isArray arguments[0]
          # cmds, [options], callback
          cmds = arguments[0]
          options = arguments[1]
          callback = arguments[2]
        else if typeof arguments[0] is 'object'
          # options, callback
          options = arguments[0]
          callback = arguments[1]
          cmds = options.cmd
        if typeof options is 'function'
          callback = options
          options = {}
        cmds = [cmds] unless Array.isArray cmds
        options.interval ?= 2000
        options.code_skipped ?= 1
        ctx.log "Start wait for execution"
        ctx.emit 'wait'
        count = 0
        each(cmds)
        .on 'item', (cmd, next) ->
          run = ->
            ctx.log "Attempt #{++count}"
            ctx
            .child()
            .execute
              cmd: cmd
              code: options.code or 0
              code_skipped: options.code_skipped
            , (err, ready) ->
              if not err and not ready
                setTimeout run, options.interval
                return
              return next err if err
              ctx.log "Finish wait for execution"
              ctx.emit 'waited'
              next()
          run()
        .on 'both', callback

## Wait for an open port

Argument "host" is a string and argument "port" is a number:   
`waitForConnection(host, port, [options], callback)`

Argument "hosts" is an array of string and argument "port" is a number:   
`waitForConnection(hosts, port, [options], callback)`

Argument "servers" is an array of objects with the "host" and "port" properties:   
`waitForConnection(servers, [options], callback)`

Ensure that the user provided callback will not be called until one or multiple 
ports are open.

*   `timeout`   
    Maximum time to wait until this function is considered to have failed.   
*   `randdir`
    Directory where to write temporary file used internally to triger a 
    timeout, default to "/tmp".   

Example waiting for the active and standby NameNodes:

```coffee
ctx.waitIsOpen ["master1.hadoop", "master2.hadoop"], 8020, (err) ->
  # do something
```

is equivalent to:

```coffee
ctx.waitIsOpen [
  {host: "master1.hadoop", port: 8020}
  {host: "master2.hadoop", port: 8020}
], (err) ->
  # do something
```

      inc = 0
      ctx.waitIsOpen = ->
        if typeof arguments[0] is 'string'
          if Array.isArray arguments[1]
             # host, ports, [options], callback
            servers = for port in arguments[1]
              host: arguments[0], port: port
            options = arguments[2]
            callback = arguments[3]
          else
            # host, port, [options], callback
            servers = [host: arguments[0], port: arguments[1]]
            options = arguments[2]
            callback = arguments[3]
        else if Array.isArray(arguments[0]) and typeof arguments[1] is 'number'
          # hosts, port, [options], callback
          servers = for h in arguments[0] then host: h, port: arguments[1]
          options = arguments[2]
          callback = arguments[3]
        else
          # servers, [options], callback
          servers = arguments[0]
          options = arguments[1]
          callback = arguments[2]
        if typeof options is 'function'
          callback = options
          options = {}
        servers_flatten = []
        # Normalize
        for server in servers
          if Array.isArray server.port
            for port in server.port then servers_flatten.push host: server.host, port: port
          else
            servers_flatten.push host: server.host, port: server.port
        return callback() unless servers_flatten.length
        quorum_target = options.quorum
        if quorum_target and quorum_target is 'true'  
          quorum_target = Math.ceil servers_flatten.length / 2
        else
          quorum_target = servers_flatten.length
        quorum_current = 0
        randfiles = []
        each servers_flatten
        .parallel true
        .on 'item', (server, next) ->
          options.randdir ?= '/tmp'
          rand = Date.now() + inc++
          randfiles.push randfile = "#{options.randdir}/#{rand}"
          if options.timeout
            timedout = false
            clear = setTimeout ->
              timedout = true
              ctx
              .child()
              .touch
                destination: randfile
              , (err) -> # nothing to do
            , options.timeout
          #   cmd = "while ! `bash -c 'echo > /dev/tcp/#{server.host}/#{server.port}'` && [[ ! -f #{randfile} ]]; do sleep 2; done;"
          # else
          #   cmd = "while ! bash -c 'echo > /dev/tcp/#{server.host}/#{server.port}'; do sleep 2; done;"
          cmd = "echo > #{randfile}; while ! `bash -c 'echo > /dev/tcp/#{server.host}/#{server.port}'` && [[ -f #{randfile} ]]; do sleep 2; done;"
          ctx.log "Start wait for #{server.host} #{server.port}"
          ctx.emit 'wait', server.host, server.port
          ctx
          .execute
            cmd: cmd
            shy: true
          , (err, executed) ->
            clearTimeout clear if clear
            err = new Error "Reached timeout #{options.timeout}" if not err and timedout
            ctx.log "Finish wait for #{server.host} #{server.port}"
            ctx.emit 'waited', server.host, server.port
            quorum_current++ unless err
            cmd = for randfile in randfiles then "rm #{randfile};"
            ctx.execute
              cmd: cmd.join '\n'
              shy: true
              if: quorum_current >= quorum_target
            , (_err_) -> next err
        .on 'both', callback

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

      ctx.connect = (config, callback) ->
        return callback null, ctx.ssh unless config?
        ctx.connections ?= {}
        if typeof config is 'string'
          destctx = ctx.hosts[config]
          require('./connection').configure destctx
          config = destctx.config.connection
        ctx.log "SSH connection to #{config.host}"
        # Connection already created, use it
        return callback null, ctx.connections[config.host] if ctx.connections[config.host]
        do_private_key = ->
          return do_connect() if config.private_key
          ctx.log "Read private key file: #{config.private_key_location}"
          misc.path.normalize config.private_key_location, (location) ->
            fs.readFile location, 'ascii', (err, content) ->
              return next Error "Private key doesnt exists: #{JSON.encode location}" if err and err.code is 'ENOENT'
              return next err if err
              config.private_key = content
              do_connect()
        do_connect = ->
          # config.privateKey = config.private_key
          connect config, (err, connection) ->
            return callback err if err
            ctx.log "SSH connection open"
            ctx.connections[config.host] = connection
            close = (err) ->
              ctx.log "SSH connection closed for #{config.host}"
              ctx.log "Error closing connection: #{err.stack or err.message}" if err
              connection.end()
            ctx.on 'error', close
            ctx.on 'end', close
            callback null, connection
        do_private_key()

[ssh2]: https://github.com/mscdex/ssh2
[exec]: https://github.com/wdavidw/node-ssh2-exec/blob/master/src/connect.coffee.md




