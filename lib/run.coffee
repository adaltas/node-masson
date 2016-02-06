
crypto = require 'crypto'
util = require 'util'
multimatch = require 'multimatch'
pad = require 'pad'
each = require 'each'
{EventEmitter} = require 'events'
{flatten, merge} = require './misc'
context = require './context'
tree = require './tree'

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
      ctx = contexts[fqdn] = context (merge {}, config, server), params.command
      ctx.runinfo = {}
      ctx.runinfo.date = now
      ctx.runinfo.command = params.command
      ctx.hosts = contexts
      ctx.config.modules = ctx.config.modules.reverse() if params.command is 'stop'
      ctx.tree = tree ctx.config.modules
      ctx.modules = Object.keys ctx.tree.modules
    # Catch Uncaught Exception
    process.on 'uncaughtException', (err) =>
      console.log 'masson/lib/run: uncaught exception'
      # for fqdn, ctx of contexts
      #   ctx.emit 'error', err if ctx.listeners('error').length
      @emit 'error', err
    each(contexts)
    .parallel(true)
    .run (host, ctx, next) =>
      @emit 'context', ctx
      for module in Object.keys ctx.tree.modules
        module = ctx.tree.modules[module]
        module.configure.call ctx, ctx if module.configure
      # Filter by hosts
      return next() if params.hosts? and multimatch(host, params.hosts).indexOf(host) is -1
      ctx.tree.middlewares params, (err, middlewares) =>
        return next() unless middlewares?
        middlewareRun = each(middlewares)
        .run (middleware, next) =>
          ctx.middleware = middleware
          retry = if middleware.retry? then middleware.retry else 2
          middleware.wait ?= 5000
          attempts = 0
          disregard_done = false
          if middleware.skip
            ctx.emit 'middleware_skip'
            return next()
          ctx.emit 'middleware_start'
          emit_middleware = (err, status) =>
            ctx.emit 'middleware_stop', err, status
          done = (err, status) =>
            return if disregard_done
            clearTimeout timeout if timeout
            if err and (retry is true or ++attempts < retry)
              ctx.log? "Get error #{err.message}, retry #{attempts} of #{retry}"
              return setTimeout run, middleware.wait
            emit_middleware err, status
            next err
          run = =>
            ctx.retry = attempts
            ctx.call middleware
            ctx.then done
          # Timeout, default to 100s
          middleware.timeout ?= 100000
          if middleware.timeout > 0
            timeout = setTimeout ->
              retry = 0 # Dont retry on timeout or we risk to get the handler called multiple times
              done new Error "TIMEOUT after #{middleware.timeout}"
              disregard_done = true
            , middleware.timeout
          run()
        .then (err) ->
          if err
          then ctx.emit 'error', err
          else ctx.emit 'end' if params.end
          next err
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
  # tmp = (args) -> Run.apply @, args
  # tmp.prototype = Run.prototype
  # new tmp arguments
