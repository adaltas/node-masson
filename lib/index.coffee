
parameters = require 'parameters'
params = require './params'
load = require './config/load'
normalize = require './config/normalize'
store = require './config/store'
merge = require './utils/merge'

module.exports = (processOrArgv, callback) ->
  processOrArgv ?= process

  # Parse the first part of the arguments, without the user command
  orgparams = parameters(merge {}, params, main: name: 'main').parse(processOrArgv, help: false)
  
  # Read configuration
  load orgparams.config, (err, config) ->
    if err
      if callback
        return callback err
      else
        process.stderr.write "#{e.message}\n\n"
        process.exit()
    callback ?= (->)
    # Normalize coniguration
    config = normalize config
    # Enrich configuration with command discovery
    commands = {}
    for command in store(config).commands()
      commands[command] = 
        description: "Run the #{command} command"
        run: 'masson/lib/commands/run'
        options: [
          name: 'nodes', shortcut: 'n', type: 'array'
          description: 'Limit to a list of server FQDNs'
        ,
          name: 'tags', shortcut: 't', type: 'array'
          description: 'Limit to servers that honor a list of tags'
        ,
          name: 'modules', shortcut: 'm', type: 'array'
          description: 'Limit to a list of modules'
        ,
          name: 'resume', shortcut: 'r', type: 'boolean'
          description: 'Resume from previous run'
        ]
    # Merge default parameters with discovered parameters and user parameters
    merge params, commands: commands, config.params
    try
      parameters(params).parse processOrArgv
    catch err
      process.stderr.write "#{err.message}\n\n"
      process.exit()
    parameters(params).run processOrArgv, config, callback
      
