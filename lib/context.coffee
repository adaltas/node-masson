
mecano = require 'mecano'
{EventEmitter} = require 'events'
{flatten, merge} = require './misc'

class Context extends EventEmitter
  constructor: (contexts, @config, @command)->
    @_contexts = contexts
    options = {}
    options.cache = true
    options.store = {}
    options[k] = v for k, v of @config.mecano
    mecano @, options
    @
  run: (ctx, module) ->
    if typeof module is 'function'
      module.call ctx
    else
      throw new Error 'Only accept functions for now'
  context: (host, modules=[]) ->
    host_ctx = @_contexts[host]
    throw Error "Invalid host: #{JSON.stringify host}" unless host? and host_ctx?
    modules = [modules] unless Array.isArray modules
    for module in modules
      host_ctx.run host_ctx, module
    host_ctx
  contexts: (query={}, modules=[]) ->
    return (for _, host of @_contexts then host) unless arguments.length
    query = modules: query if typeof query is 'string' or Array.isArray query
    query.hosts ?= []
    query.hosts = [query.hosts] unless Array.isArray query.hosts
    query.modules ?= []
    query.modules = [query.modules] unless Array.isArray query.modules
    hosts = {}
    # console.log 'contexts', query
    for host in query.hosts then hosts[host] = null
    for host in @hosts_with_module(query.modules) then hosts[host] = null
    hosts = Object.keys hosts
    for host in hosts
      @context host, modules
  # Return a server for a given action
  # Throw an error in strict mode if no server or more than one server is found.
  host_with_module: (module, strict) ->
    servers = []
    for host, ctx of @_contexts
      servers.push host if ctx.modules.indexOf(module) isnt -1
    throw new Error "Too many hosts with module #{module}: #{servers.length}" if servers.length > 1
    throw new Error "No host found for module #{module}" if strict and servers.length is 0
    servers[0]
  # Return a list of servers referencing one or multiple modules
  hosts_with_module: (modules, qtt, strict, null_if_empty) ->
    servers = []
    modules = [modules] unless Array.isArray modules
    # console.log 'hosts_with_module modules', modules
    for module in modules
      for host, ctx of @_contexts
        # console.log 'hosts_with_module', ctx.modules
        servers.push host if ctx.modules.indexOf(module) isnt -1
    throw new Error "Expect #{qtt} host(s) for module #{module} but got #{servers.length}" if strict and qtt? and servers.length isnt qtt
    return null if servers.length is 0 and null_if_empty
    if qtt is 1 then servers[0] else servers
  has_module: (module) ->
    @modules.indexOf(module) isnt -1
  has_all_modules: (modules...) ->
    modules = flatten modules
    for module in modules
      return false unless @has_module module
    return true
  has_any_modules: (modules...) ->
    has_module = []
    modules = flatten modules
    for module in modules
      has_module.push module if @has_module module
    return if has_module.length then has_module else false
    

module.exports = (config, command) ->
  return new Context config, command
module.exports.Context = Context
