
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
Run = (config, params) ->
  EventEmitter.call @
  @setMaxListeners 100
  @config = config
  @params = params
  setImmediate =>
    # Work on each server
    contexts = {}
    shared = {}
    each(config.servers)
    .parallel(true)
    .on 'item', (host, hconfig, next) =>
      ctx = contexts[host] = context (merge {}, config, hconfig), params.command
      ctx.hosts = contexts
      ctx.shared = shared
      ctx.config.modules = ctx.config.modules.reverse() if params.command is 'stop'
      ctx.tree = tree ctx.config.modules
      ctx.modules = Object.keys ctx.tree.modules
      next()
    .on 'error', (err) =>
      @emit 'error', err
    .on 'end', =>
      process.on 'uncaughtException', (err) =>
        for host, ctx of contexts
          ctx.emit 'error', err if ctx.listeners('error').length
        @emit 'error', err
      each(config.servers)
      .parallel(true)
      .on 'item', (host, config, next) =>
        # Filter by hosts
        return next() if params.hosts? and multimatch(host, params.hosts).indexOf(host) is -1
        ctx = contexts[host]
        # ctx.run = @
        @emit 'context', ctx
        ctx.tree.middlewares params, (err, middlewares) =>
        # @middlewares host, params.command, params, (err, middlewares) =>
          # return next new Error "Invalid run list: #{@params.command}" unless middlewares?
          return next() unless middlewares?
          # middlewares = middlewares.reverse() if params.command is 'stop'
          middlewareRun = each(middlewares)
          .on 'item', (middleware, next) =>
            ctx.middleware = middleware
            retry = if middleware.retry? then middleware.retry else 2
            middleware.wait ?= 1
            attempts = 0
            disregard_done = false
            if middleware.skip
              ctx.emit 'middleware_skip'
              return next()
            ctx.emit 'middleware_start'
            emit_middleware = (err, status) =>
              ctx.emit 'middleware_stop', err, status
            done = (err, statusOrMsg) =>
              return if disregard_done
              clearTimeout timeout if timeout
              if err and (retry is true or ++attempts < retry)
                ctx.log? "Get error #{err.message}, retry #{attempts} of #{retry}"
                return setTimeout run, middleware.wait
              emit_middleware err, statusOrMsg
              next err
            run = =>
              ctx.retry = attempts
              try
                # Synchronous middleware
                if middleware.handler.length is 0 or middleware.handler.length is 1
                  merge middleware, middleware.handler.call ctx, ctx
                  process.nextTick ->
                    middleware.timeout = -1
                    done()
                # Asynchronous middleware
                else
                  merge middleware, middleware.handler.call ctx, ctx, (err, statusOrMsg) =>
                    done err, statusOrMsg
              catch e
                retry = false # Dont retry unhandled errors
                done e
            # Timeout, default to 100s
            middleware.timeout ?= 100000
            if middleware.timeout > 0
              timeout = setTimeout ->
                retry = 0 # Dont retry on timeout or we risk to get the handler called multiple times
                done new Error 'TIMEOUT'
                disregard_done = true
              , middleware.timeout
            run()
          .on 'both', (err) =>
            @emit 'server', ctx, err
            if err 
            then (ctx.emit 'error', err if ctx.listeners('error').length)
            else ctx.emit 'end'
            next err
      .on 'error', (err) =>
        @emit 'error', err
      .on 'end', (err) =>
        @emit 'end'
  @
util.inherits Run, EventEmitter

module.exports = (config, params) ->
  new Run config, params

