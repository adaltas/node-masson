
crypto = require 'crypto'
fs = require 'fs'
path = require 'path'
parameters = require 'parameters'
util = require 'util'
pad = require 'pad'
each = require 'each'
{merge} = require 'mecano/lib/misc'
{flatten} = require './misc'
load = require './load'
context = require './context'

parameters = parameters
  name: 'big'
  description: 'Hadoop DSP-IT development cluster'
  options: [
    name: 'config', shortcut: 'c'
    description: 'Configuration file'
  , 
    name: 'debug', shortcut: 'd', type: 'boolean'
    description: 'Print readable stacktrace'
  ]
  action: 'command'
  actions: [
    name: 'help'
    main: name: 'subcommand'
  ,
    name: 'install'
    description: 'Install components and deploy configuration'
    options: [
      name: 'hosts', shortcut: 'h'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
    ,
      name: 'actions', shortcut: 'a'
      description: 'Limit to a list of actions'
    , 
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ,
    name: 'start'
    description: 'Start server components'
    options: [
      name: 'hosts', shortcut: 'h'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
    ,
      name: 'actions', shortcut: 'a'
      description: 'Limit to a list of actions'
    ]
  ,
    name: 'stop',
    description: 'Stop server components'
    options: [
      name: 'hosts', shortcut: 'h'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
    ,
      name: 'actions', shortcut: 'a'
      description: 'Limit to a list of actions'
    ]
  ,
    name: 'check',
    description: 'Clean the server',
    options: [
      name: 'hosts', shortcut: 'h'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
    ,
      name: 'actions', shortcut: 'a'
      description: 'Limit to a list of actions'
    ]
  ,
    name: 'clean'
    description: 'Clean the server'
    options: [
      name: 'hosts', shortcut: 'h'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
    ,
      name: 'actions', shortcut: 'a'
      description: 'Limit to a list of actions'
    ]
  ]
params = parameters.parse()
params.hosts = params.hosts.split ',' if params.hosts
params.roles = params.roles.split ',' if params.roles
params.actions = params.actions.split ',' if params.actions
# Print help
return util.print parameters.help params.subcommand if params.command is 'help'
# Load configuration
try
  config = if params.config then "#{path.resolve process.cwd(), params.config}" else '../data/config.coffee'
  config = require config
catch e
  process.stderr.write "Fail to load configuration file: #{config}\n"
  return console.log e
# Work on each server
each(config.servers)
.parallel(true)
.on 'item', (server, next) ->
  # Filter by hosts
  return next() if params.hosts? and params.hosts.indexOf(server.host) is -1
  # Cache modules for current server
  server._cache = {}
  # Cache the topings already executed
  server._called = {}
  # List actions
  actions = []
  roles = server.run[params.command]
  return util.print "\x1b[31mCommand '#{params.command}' not registered for server '#{server.host}'\x1b[39m\n" unless roles?
  for role in roles
    # Filter by roles
    continue if params.roles? and params.roles.indexOf(role) is -1
    for action in config.roles[role]
      # Filter by actions
      continue if params.actions? and params.actions.indexOf(action) is -1
      actions.push action
  actions.unshift 'histi/actions/bootstrap'
  return next() unless actions.length
  ctx = context (merge {}, config, server), params.command
  ctx.meta = {}
  ctx.name = (name) ->
    @meta.name = name
  ctx.timeout = (timeout) ->
    @meta.timeout = timeout
  actionsEacher = each(actions)
  .on 'item', (action, nextAction) ->
    server._called[action] = true
    # [action, command] = action.split('#')
    # command ?= params.command
    try
      toppings = load action
    catch err
      return nextAction err
    if typeof toppings is 'function'
      toppings = [toppings]
    toppings = flatten toppings
    toppingsEacher = each(toppings)
    .on 'item', (topping, index, next) ->
      return next() if server._called["#{action}##{index}"]
      server._called["#{action}##{index}"] = true
      # Dependencies
      if typeof topping is 'string'
        return next() if params.fast
        actionsEacher.unshift action
        actionsEacher.unshift topping
        return nextAction()
      print = (err, msg) ->
        if err or msg is ctx.TIMEOUT or msg is ctx.FAILED
          # ctx.meta.name ?= "#{action}/#{params.command}/#{index}"
          ctx.meta.name ?= "#{action}/##{index}"
        else
          return unless ctx.meta.name
        util.print "#{pad server.host, 40}" if config.servers.length
        util.print "#{pad ctx.meta.name, 40}"
        util.print if err
          "\x1b[35m#{err.message}\x1b[39m\n"
        else if typeof msg is 'number'
          switch msg
            when ctx.PASS then "\x1b[36m#{ctx.PASS_MSG}\x1b[39m\n"
            when ctx.OK then "\x1b[36m#{ctx.OK_MSG}\x1b[39m\n"
            when ctx.FAILED then "\x1b[36m#{ctx.FAILED_MSG}\x1b[39m\n"
            when ctx.DISABLED then "\x1b[36m#{ctx.DISABLED_MSG}\x1b[39m\n"
            when ctx.TODO then "\x1b[36m#{ctx.TODO_MSG}\x1b[39m\n"
            when ctx.PARTIAL then "\x1b[36m#{ctx.PARTIAL_MSG}\x1b[39m\n"
            when ctx.STOP then "\x1b[35m#{ctx.STOP_MSG}\x1b[39m\n"
            when ctx.TIMEOUT then "\x1b[35m#{ctx.TIMEOUT_MSG}\x1b[39m\n"
            when ctx.WARN then "\x1b[33m#{ctx.WARN_MSG}\x1b[39m\n"
            else "INVALID CODE\n"
        else "\x1b[36m#{msg or 'UNKNOWN'}\x1b[39m\n"
      checksum = crypto.createHash('md5').update(topping.toString()).digest('hex')
      return next() if server._cache[checksum]
      # Meta
      ctx.meta = meta = {}
      # Cleanup and pass to the next action
      done = (err) ->
        process.removeListener 'uncaughtException', onUncaughtException
        next err
      # Catch the uncatchable
      onUncaughtException = (err) ->
        clearTimeout timeout if timeout
        print err
        done new Error err
      process.on 'uncaughtException', onUncaughtException
      # Synchronous action
      if topping.length is 1
        merge meta, topping.call ctx, ctx
        meta.timeout = -1
        server._cache[checksum] = true unless meta.multiple
        done()
      # Asynchronous action
      else
        count = 0
        merge meta, topping.call ctx, ctx, (err, msg) ->
          # Deal with timeout
          meta.timeout = -1 # callback may be called before meta is return in sync mode
          clearTimeout timeout if timeout
          return if timedout
          print err, msg
          return toppingsEacher.end() if msg is ctx.STOP
          done err
        server._cache[checksum] = true unless meta.multiple
      # Timeout, default to 5s
      # meta ?= {}
      meta.timeout ?= 100000
      return if meta.timeout is -1
      timedout = false
      timeout = setTimeout ->
        timedout = true
        print null, ctx.TIMEOUT
        done new Error 'TIMEOUT'
      , meta.timeout
    .on 'both', (err) ->
      nextAction err
  .on 'both', (err) ->
    util.print pad server.host, 40
    if err
      util.print "\x1b[31mERROR\x1b[39m\n"
      ctx.emit 'error', err
    else 
      util.print "\x1b[32mSUCCESS\x1b[39m\n"
      ctx.emit 'end'
    next()
.on 'both', (err) ->
  util.print "\x1b[32mInstallation is finished\x1b[39m\n"
  throw err if err
