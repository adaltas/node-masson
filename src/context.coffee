
{EventEmitter} = require 'events'
{flatten, merge} = require './misc'
tree = require './tree'

class Context extends EventEmitter
  constructor: (@config, @command)->
    @PASS = 0
    @PASS_MSG = 'STABLE' #STABLE
    @OK = 1
    @OK_MSG = 'OK' #SUCCESS
    @FAILED = 2
    @FAILED_MSG = 'ERROR' #ERROR
    @DISABLED = 3
    @DISABLED_MSG = 'DISABLED'
    @TODO = 4
    @TODO_MSG = 'TODO'
    @STARTED = 5
    @STARTED_MSG = 'RUNNING' #START
    @STOP = 6
    @STOP_MSG = 'STOPPED' # CANCELED
    @TIMEOUT = 7
    @TIMEOUT_MSG = 'TIMEOUT'
    @WARN = 8
    @WARN_MSG = 'WARNING'
    @INAPPLICABLE = 9
    @INAPPLICABLE_MSG = 'SKIPPED'
    @tmp = {}
  # Return a server for a given action
  # Throw an error in strict mode if no server or more than one server is found.
  host_with_module: (module, strict) ->
    servers = []
    for host, ctx of @hosts
      servers.push host if ctx.modules.indexOf(module) isnt -1
    throw new Error "Too many hosts with module #{module}: #{servers.length}" if servers.length > 1
    throw new Error "No host found for module #{module}" if strict and servers.length is 0
    servers[0]
  # Return a list of servers with a give action
  hosts_with_module: (module, qtt, strict, null_if_empty) ->
    servers = []
    for host, ctx of @hosts
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
    modules = flatten modules
    for module in modules
      return true if @has_module module
    return false
    

module.exports = (config, command) ->
  return new Context config, command
module.exports.Context = Context
