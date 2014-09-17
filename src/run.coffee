
crypto = require 'crypto'
util = require 'util'
multimatch = require 'multimatch'
pad = require 'pad'
each = require 'each'
{EventEmitter} = require 'events'
{flatten, merge} = require './misc'
context = require './context'
{Tree} = require './tree'

###
The execution is done in 2 passes.

On the first pass, a context object is build for each server. A context is the 
same object inject to a callback action as first argument. In a context, other 
server contexts are available through the `hosts` object where keys are the 
server name. A context object is enriched with the "actions" and "modules" 
properties which are respectively a list of "actions" and a list of modules.

On the second pass, the action are executed.
###
Run = (config, params) ->
  EventEmitter.call @
  @setMaxListeners 100
  @config = config
  @params = params
  @tree = new Tree 
  # @tree = new Tree 
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
      @actions host, 'install', {}, (err, actions) =>
        return next err if err
        ctx.actions = actions or []
        @modules host, 'install', {}, (err, modules) =>
          return next err if err
          ctx.modules = modules or []
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
        ctx.run = @
        @emit 'context', ctx
        @actions host, params.command, params, (err, actions) =>
          # return next new Error "Invalid run list: #{@params.command}" unless actions?
          return next() unless actions?
          actionRun = each(actions)
          .on 'item', (action, next) =>
            return next() if action.skip
            # Action
            ctx.action = action
            retry = if action.retry? then actions.retry else 2
            attempts = 0
            disregard_done = false
            emit_action = (status) =>
              ctx.emit 'action', status
            emit_action ctx.STARTED
            done = (err, statusOrMsg) =>
              return if disregard_done
              clearTimeout timeout if timeout
              if err and (retry is true or ++attempts < retry)
                ctx.log? "Get error #{err.message}, retry #{attempts} of #{retry}"
                return setTimeout(run, 1) 
              if err
              then emit_action ctx.FAILED
              else emit_action statusOrMsg
              next err
            run = =>
              try
                # Synchronous action
                if action.callback.length is 1
                  merge action, action.callback.call ctx, ctx
                  process.nextTick ->
                    action.timeout = -1
                    done null, ctx.DISABLED
                # Asynchronous action
                else
                  merge action, action.callback.call ctx, ctx, (err, statusOrMsg) =>
                    actionRun.end() if statusOrMsg is ctx.STOP
                    done err, statusOrMsg
              catch e then done e
            # Timeout, default to 100s
            action.timeout ?= 100000
            if action.timeout > 0
              timeout = setTimeout ->
                retry = 0 # Dont retry on timeout or we risk to get the callback called multiple times
                done new Error 'TIMEOUT'
                disregard_done = true
              , action.timeout
            run()
          .on 'both', (err) =>
            @emit 'server', ctx, if err then ctx.FAILED else ctx.OK
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

###
Return all the actions for a given host and the current command 
or null if the host didnt register any run list for this command.
###
Run::actions = (host, command, options, callback) ->
  # Get the server config
  # for server in @config.servers
  #   config = server if server.host is host
  config = @config.servers[host]
  return callback new Error "Invalid host: #{host}" unless config
  # Check the run list
  run = config.run[command]
  return callback null unless run
  # return callback new Error "Invalid run list: #{@params.command}" unless run
  @tree.actions run, options, (err, actions) =>
    return callback err if err
    callback null, actions

###
Return all the modules for a given host and the current command 
or null if the host didnt register any run list for this command.
###
Run::modules = (host, command, options, callback) ->
  # Get the server config
  # for server in @config.servers
  #   config = server if server.host is host
  config = @config.servers[host]
  return callback new Error "Invalid host: #{host}" unless config
  # Check the run list
  run = config.run[command]
  return callback null unless run
  # return callback new Error "Invalid run list: #{@params.command}" unless run
  @tree.modules run, options, (err, modules) =>
    return callback err if err
    callback null, modules

module.exports = (config, params) ->
  new Run config, params

