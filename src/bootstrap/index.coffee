###
bootstrap
=========

Bootstrap will initialize an SSH connection accessible 
throught the context object as `ctx.ssh`. The connection is 
initialized with the root user.
###

tty = require 'tty'
pad = require 'pad'
readline = require 'readline'
mecano = require 'mecano'
fs = require 'fs'
{merge} = require 'mecano/lib/misc'
connect = require 'superexec/lib/connect'
collect = require './collect'
bootstrap = require './bootstrap'
module.exports = []

###
Configuration
-------------
###
module.exports.push (ctx) ->
  ctx.config.bootstrap ?= {}
  ctx.config.bootstrap.host ?= if ctx.config.ip then ctx.config.ip else ctx.config.host
  ctx.config.bootstrap.port ?= ctx.config.port or 22
  ctx.config.bootstrap.public_key ?= []
  if typeof ctx.config.bootstrap.public_key is 'string'
    ctx.config.bootstrap.public_key = [ctx.config.bootstrap.public_key]
  ctx.config.bootstrap.cmd ?= 'su -'

###
Log
----
Gather system information
###
module.exports.push (ctx, next) ->
  @name 'Bootstrap # Log'
  mecano.mkdir
    destination: './logs'
  , (err, created) ->
    return next err if err
    # Add log interface
    ctx.log = log = (msg) ->
      log.out.write "#{msg}\n"
    log.out = fs.createWriteStream "./logs/#{ctx.config.host}_out.log"
    log.err = fs.createWriteStream "./logs/#{ctx.config.host}_err.log"
    pname = ctx.name
    close = ->
      setTimeout ->
        log.out.close()
        log.err.close()
      , 100
    ctx.on 'end', close
    # Log action name
    ctx.name = (name) ->
      msg = "\n#{name}\n#{pad name.length, '', '-'}\n"
      log.out.write msg
      log.err.write msg
      pname.apply @, arguments
    # Catch error
    ctx.on 'error', (err) ->
      print = (err) ->
        log.err.write err.message
        log.err.write err.stack if err.stack
      print err
      if err.errors
        for error in err.errors then print error
      close()
    # Log uncatch exception
    process.on 'uncaughtException', (err) ->
      log.err.write err.stack
    next null, ctx.PASS

###
Connection
----------
Prepare the system to receive password-less root login and 
initialize an SSH connection.
###
module.exports.push (ctx, next) ->
  @name 'Bootstrap # Connection'
  @timeout -1
  close = -> ctx.ssh?.end()
  ctx.on 'error', close
  ctx.on 'end', close
  attempts = 0
  ssh = ->
    attempts++
    ctx.log "SSH login #{attempts}"
    config = merge {}, ctx.config.bootstrap,
      username: 'root'
      password: null
    connect config, (err, connection) ->
      if attempts isnt 0 and err and (err.code is 'ETIMEDOUT' or err.code is 'ECONNREFUSED')
        ctx.log 'Wait for reboot'
        return setTimeout ssh, 1000
      return coll() if err and attempts is 1
      return next err if err
      ctx.ssh = connection
      next null, ctx.PASS
  coll = ->
    ctx.log 'Collect login information'
    collect ctx.config.bootstrap, (err) ->
      return next err if err
      boot()
  boot = ->
    ctx.log 'Deploy ssh key'
    bootstrap ctx, (err) ->
      return next err if err
      ctx.log 'Reboot and login'
      ssh()
  ssh()

###
Server Info
----
Gather system information.
###
module.exports.push (ctx, next) ->
  @name 'Bootstrap # Server Info'
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

###
Mecano
----
Predefined Mecano functions with context related information.
For example, this:

  mecano.execute
    ssh: ctx.ssh
    cmd: 'ls -l'
    stdout: ctx.log.out
    stderr: ctx.log.err
  , (err, executed) ->
    ...

Is similiar to:

  ctx.execute
    cmd: 'ls -l'
  , (err, executed) ->
    ...
###
module.exports.push (ctx, next) ->
  @name 'Bootstrap # Mecano'
  m = (action, options) ->
    options.ssh ?= ctx.ssh
    options.log ?= ctx.log
    options.stdout ?= ctx.log.out
    options.stderr ?= ctx.log.err
    # if action is 'service'
    options.installed = ctx.installed
    options.updates = ctx.updates
    options
  ['copy', 'download', 'execute', 'extract', 'git', 
   'ini', 'ldap_acl', 'ldap_index', 'ldap_schema', 
   'link', 'mkdir', 'move', 'remove', 'render', 
   'service', 'upload', 'write'
  ].forEach (action) ->
    ctx[action] = (options, callback) ->
      if action is 'mkdir' and typeof options is 'string'
        options = m action, destination: options
      if Array.isArray options
        for opts, i in options
          options[i] = m action, opts
      else
        options = m action, options
      if action is 'service'
        mecano[action].call null, options, (err) ->
          unless err
            ctx.installed = arguments[2]
            ctx.updates = arguments[3]
          callback.apply null, arguments
      else
        # Some mecano actions rely on `callback.length`
        mecano[action].call null, options, callback
  next null, ctx.PASS

module.exports.push (ctx) ->
  @name 'Bootstrap # Utils'
  ctx.reboot = (callback) ->
    attempts = 0
    reboot = ->
      ctx.log "Reboot"
      child = ctx.execute
        cmd: 'reboot\n'
      , (err, executed, stdout, stderr) ->
        return callback err if err
        # wait() if /going down/.test stdout
        wait()
      # child.stdout.on 'data', (data) ->
      #   data = data.toString()
      #   wait() if /going down/.test data
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
    reboot()













