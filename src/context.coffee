
{EventEmitter} = require 'events'
{merge} = require 'mecano/lib/misc'

class Context extends EventEmitter
  constructor: (@config, @command)->
    @PASS = 0
    @PASS_MSG = 'PASS'
    @OK = 1
    @OK_MSG = 'OK'
    @FAILED = 2
    @FAILED_MSG = 'FAILED'
    @DISABLED = 3
    @DISABLED_MSG = 'DISABLED'
    @TODO = 4
    @TODO_MSG = 'TODO'
    @PARTIAL = 5
    @PARTIAL_MSG = 'PARTIAL'
    @STOP = 6
    @STOP_MSG = 'STOP'
    @TIMEOUT = 7
    @TIMEOUT_MSG = 'TIMEOUT'
    @WARN = 8
    @WARN_MSG = 'WARN'
    @tmp = {}
  # Return all the servers matching the provided filter. 
  # Filter may contains action and role
  servers: (filter = {}) ->
    filter.role = [filter.role] if typeof filter.role is 'string'
    filter.action = [filter.action] if typeof filter.action is 'string'
    if not filter.role? and not filter.action?
      return @config.servers.map (server) -> server.host
    servers = []
    breaking = false
    for serverConf in @config.servers
      for role in serverConf.run[@command]
        if filter.role and filter.role.indexOf(role) isnt -1
          servers.push serverConf.host
          break
        roleConf = @config.roles[role]
        for action in roleConf
          if filter.action and filter.action.indexOf(action) isnt -1
            servers.push serverConf.host
            break
    servers
  hasAction: (action) ->
    @servers(action: action).indexOf(@config.host) isnt -1

module.exports = (config, command) ->
  return new Context config, command
module.exports.Context = Context
