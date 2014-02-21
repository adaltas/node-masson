
crypto = require 'crypto'
util = require 'util'
pad = require 'pad'
each = require 'each'
{EventEmitter} = require 'events'
{merge} = require 'mecano/lib/misc'
{flatten} = require './misc'
load = require './load'
context = require './context'
{Tree} = require './tree'

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
    .on 'item', (server, next) =>
      contexts[server.host] = context (merge {}, config, server), params.command
      @actions server.host, 'install', {}, (err, actions) =>
        return next err if err
        contexts[server.host].actions = actions or []
        @modules server.host, 'install', {}, (err, modules) =>
          return next err if err
          contexts[server.host].modules = modules or []
          next()
    .on 'error', (err) =>
      @emit 'error', err
    .on 'end', =>
      each(config.servers)
      .parallel(true)
      .on 'item', (server, next) =>
        # Filter by hosts
        return next() if params.hosts? and params.hosts.indexOf(server.host) is -1
        ctx = contexts[server.host]
        ctx.run = @
        ctx.shared = shared
        ctx.hosts = contexts
        @actions server.host, params.command, params, (err, actions) =>
          # return next new Error "Invalid run list: #{@params.command}" unless actions?
          return next() unless actions?
          actionRun = each(actions)
          .on 'item', (action, next) =>
            return next() if action.skip
            # Action
            ctx.action = action
            timedout = null
            emit_action = (status) =>
              ctx.emit 'action', status
              @emit 'action', ctx, status
            emit_action ctx.STARTED
            # @emit 'action', ctx, ctx.STARTED
            # Cleanup and pass to the next action
            done = (err, statusOrMsg) =>
              clearTimeout timeout if timeout
              timedout = true
              if err
              then emit_action ctx.FAILED
              else emit_action statusOrMsg
              # then @emit 'action', ctx, ctx.FAILED
              # else @emit 'action', ctx, statusOrMsg
              next err
            # Timeout, default to 100s
            action.timeout ?= 100000
            if action.timeout > 0
              timeout = setTimeout ->
                timedout = true
                done new Error 'TIMEOUT'
              , action.timeout
            try
              # Prevent "Maximum call stack size exceeded" when
              # timeout, interval and setImmediate is used inside the callback
              setImmediate =>
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
          .on 'both', (err) =>
            @emit 'server', ctx, if err then ctx.FAILED else ctx.OK
            if err 
            then (ctx.emit 'error', err if ctx.listeners('error').length)
            else ctx.emit 'end', ctx
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
  for server in @config.servers
    config = server if server.host is host
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
  for server in @config.servers
    config = server if server.host is host
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

