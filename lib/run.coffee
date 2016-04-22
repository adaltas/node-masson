
path = require 'path'
util = require 'util'
multimatch = require './multimatch'
each = require 'each'
{EventEmitter} = require 'events'
{flatten, merge} = require './misc'
context = require './context'
Module = require 'module'

###
The execution is done in 2 passes.

On the first pass, a context object is build for each server. A context is the 
same object inject to a middleware as first argument. In a context, other 
server contexts are available through the `hosts` object where keys are the 
server name. A context object is enriched with the "middlewares" and "modules" 
properties which are respectively a list of "middlewares" and a list of modules.

On the second pass, the middewares are executed.
###
Run = (params, config) ->
  now = new Date()
  params.end ?= true
  EventEmitter.call @
  @setMaxListeners 100
  setImmediate =>
    # Work on each server
    contexts = {}
    for fqdn, server of config.servers
      ctx = contexts[fqdn] = context contexts, (merge {}, config, server)
      ctx.params = params
      ctx.runinfo = {}
      ctx.runinfo.date = now
      ctx.runinfo.command = params.command
      # ctx.config.modules = ctx.config.modules.reverse() if params.command is 'stop'
    process.on 'uncaughtException', (err) =>
      console.log 'masson/lib/run: uncaught exception'
      @emit 'error', err
    # Discover module inside parent project
    for p in Module._nodeModulePaths path.resolve '.'
      require.main.paths.push p
    each contexts
    .parallel true
    .call (ctx, next) =>
      @emit 'context', ctx
      middlewares = []
      for name in ctx.config.modules
        m = load_module(ctx, name, 'install')
        if m then for middleware in m
          if middleware.irreversible or params.command isnt 'stop' 
          then middlewares.push middleware
          else middlewares.unshift middleware
        # middlewares.push m...
      # Export list of modules
      ctx.middlewares = middlewares
      ctx.modules = middlewares.map( (m) -> m.module ).reduce( (p, c) ->
        p.push(c) if p.indexOf(c) < 0; p
      , [] )
      next()
    .call (ctx, next) ->
      call_modules ctx, command: 'configure', next
    .call (ctx, next) ->
      call_modules ctx, params, next
    .then (err) =>
      if err
      then @emit 'error', err 
      else @emit 'end'  
  @
util.inherits Run, EventEmitter

module.exports = (options, config) ->
  if arguments.length is 1
    config = options
    options = {}
  new Run options, config

# Configuration
load_module = (ctx, parent, default_command, filter_command) ->
  middlewares = []
  parent = module: parent if typeof parent is 'string'
  plugin = false
  if not parent.handler or typeof parent.handler is 'string'
    absname = parent.module
    absname = path.resolve process.cwd(), parent.module if parent.module.substr(0, 1) is '.'
    mod = require.main.require absname
    plugin = true if typeof mod is 'function'
    mod = handler: mod unless mod.handler
    throw Error "Invalid handler in #{parent.module}" if typeof mod.handler isnt 'function'
    parent.handler = undefined
    parent[k] ?= v for k, v of mod
  if plugin
    middlewares.push module: parent.module, plugin: true
    commands = parent.handler.call ctx
    return unless commands
    return if commands is ctx
    for command, children of commands
      # when a plugin reference another plugin, we need to filterout other
      # commands while preserving configure
      continue if filter_command and command isnt 'configure' and command isnt filter_command
      continue unless children
      children = [children] unless Array.isArray children
      for child in children
        if typeof child is 'string'
          child = handler: child
        else if typeof child is 'function'
          child = handler: child
        else if not child? or Array.isArray(child) or typeof child isnt 'object'
          throw Error "Invalid child: #{child}"
        if typeof child.handler is 'string'
          child.module = child.handler
        else if typeof child.handler is 'function'
          child.module = parent.module
        else
          throw Error "Invalid handler: #{child.handler}"
        child.command ?= command
        m = load_module(ctx, child, default_command, command)
        middlewares.push m... if m
  else
    # parent.command ?= default_command
    middlewares.push parent
  middlewares

call_modules = (ctx, params, next) ->
  # Filter by hosts
  return if params.hosts? and (multimatch ctx.config.host, params.hosts).length is 0
  # Action
  ctx.called ?= {}
  for middleware in ctx.middlewares then do (middleware) ->
    return if middleware.plugin
    # return if command isnt 'install' and middleware.command and middleware.command isnt command
    return if middleware.command and middleware.command isnt params.command
    return if not middleware.command and params.command in ['configure', 'prepare']
    return if ctx.called[middleware.module]
    ctx.called[middleware.module] = true
    if middleware.skip
      ctx.emit 'middleware_skip'
      return
    # Load handler
    if typeof middleware.handler is 'string'
      mod = require.main.require middleware.handler
      mod = handler: mod unless mod.handler
      middleware[k] = v for k, v of mod
    # Filter by modules
    return if not middleware.required and params.modules? and (multimatch middleware.module, params.modules).length is 0
    ctx.call -> ctx.emit 'middleware_start', middleware
    ctx.call middleware, (err, status) ->
      ctx.emit 'middleware_stop', middleware, err, status
  ctx.then (err, status) ->
    ctx.emit 'error', err if err
    ctx.emit 'end' if params.end
    next err
