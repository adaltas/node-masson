---
title: Utils
module: masson/bootstrap/utils
layout: module
---

# Bootstrap Utils

The `utils` module enriches the bootstraping process with commonly used functions.

    each = require 'each'
    {merge} = require 'mecano/lib/misc'
    connect = require 'ssh2-connect'
    module.exports = []
    module.exports.push name: 'Bootstrap # Utils', required: true, callback: (ctx) ->

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
          config = merge {}, ctx.config.bootstrap,
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

*   `cmd`   
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
        if typeof arguments[0] is 'string'
          # cmd, [options], callback
          cmd = arguments[0]
          options = arguments[1]
          callback = arguments[2]
        else if typeof arguments[0] is 'object'
          # options, callback
          options = arguments[0]
          callback = arguments[1]
          cmd = options.cmd
        if typeof options is 'function'
          callback = options
          options = {}
        options.interval ?= 2000
        options.code_skipped ?= 1
        ctx.log "Start wait for execution"
        ctx.emit 'wait'
        count = 0
        # running = false
        run = ->
          # return if running
          # running = true
          ctx.log "Attempt #{++count}"
          ctx.execute
            cmd: cmd
            code: options.code or 0
            code_skipped: options.code_skipped
          , (err, ready, stdout, stderr) ->
            # running = false
            #return if not err and not ready
            if not err and not ready
              setTimeout run, options.interval
              return
            return callback err if err
            # clearInterval clear if clear
            ctx.log "Finish wait for execution"
            ctx.emit 'waited'
            callback err, stdout, stderr
        # clear = setInterval ->
        #   run()
        # , options.interval
        run()
      inc = 0

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

      ctx.waitIsOpen = ->
        if typeof arguments[0] is 'string'
          if Array.isArray port
             # host, ports, [options], callback
            servers = for port in arguments[1]
              [host: arguments[0], port: port]
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
        each(servers)
        .parallel(true)
        .on 'item', (server, next) ->
          if options.timeout
            rand = Date.now() + inc++
            options.randdir ?= '/tmp'
            randfile = "#{options.randdir}/#{rand}"
            timedout = false
            clear = setTimeout ->
              timedout = true
              ctx.touch
                destination: randfile
              , (err) -> # nothing to do
            , options.timeout
            cmd = "while ! `bash -c 'echo > /dev/tcp/#{server.host}/#{server.port}'` && [[ ! -f #{randfile} ]]; do sleep 2; done;"
          else
            cmd = "while ! bash -c 'echo > /dev/tcp/#{server.host}/#{server.port}'; do sleep 2; done;"
          ctx.log "Start wait for #{server.host} #{server.port}"
          ctx.emit 'wait', server.host, server.port
          ctx.execute
            cmd: cmd
          , (err, executed) ->
            clearTimeout clear if clear
            err = new Error "Reached timeout #{options.timeout}" if not err and timedout
            ctx.log "Finish wait for #{server.host} #{server.port}"
            ctx.emit 'waited', server.host, server.port
            next err
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
        ctx.connections ?= {}
        config = (ctx.config.servers.filter (s) -> s.host is config)[0] if typeof config is 'string'
        ctx.log "SSH connection to #{config.host}"
        return callback null, ctx.connections[config.host] if ctx.connections[config.host]
        config.username ?= 'root'
        config.password ?= null
        ctx.log "SSH connection initiated"
        connect config, (err, connection) ->
          return callback err if err
          ctx.connections[config.host] = connection
          close = (err) ->
            ctx.log "SSH connection closed for #{config.host}"
            ctx.log "Error closing connection: #{err.stack or err.message}" if err
            connection.end()
          ctx.on 'error', close
          ctx.on 'end', close
          # ctx.run.on 'error', close
          # ctx.run.on 'end', close
          callback null, connection

[ssh2]: https://github.com/mscdex/ssh2
[exec]: https://github.com/wdavidw/node-ssh2-exec/blob/master/src/connect.coffee.md




