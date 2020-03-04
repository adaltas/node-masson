
parameters = require 'parameters'
params = require './params'
load = require './config/load'
normalize = require './config/normalize'
store = require './config/store'
{merge, mutate} = require 'mixme'

module.exports = (processOrArgv, callback) ->
  throw Error 'Required Argument: process or arguments is not provided' unless processOrArgv
  throw Error 'Required Argument: callback is not provided' unless callback

  # Parse the first part of the arguments, without the user command
  try
    orgparams = parameters(merge params, main: name: 'main').parse(processOrArgv)
  catch err then callback err
  
  # Read configuration
  load orgparams.config, (err, config) ->
    return callback err if err
    # Normalize configuration
    try
      config = normalize config
    catch err
      return callback err
    # Enrich configuration with command discovery
    commands = {}
    for command in store(config).commands()
      commands[command] =
        description: "Run the #{command} command on the clusters"
        route: 'masson/lib/commands/clusters'
        options:
          cluster:
            shortcut: 'c', type: 'array'
            description: 'Limit to a list of clusters'
          nodes:
            shortcut: 'n', type: 'array'
            description: 'Limit to a list of server FQDNs'
          tags:
            shortcut: 't', type: 'array'
            description: 'Limit to servers that honor a list of tags'
          modules:
            shortcut: 'm', type: 'array'
            description: 'Limit to a list of modules'
          resume:
            shortcut: 'r', type: 'boolean'
            description: 'Resume from previous run'
    # Merge default parameters with discovered parameters and user parameters
    mutate params, commands: 'clusters': commands: commands, config.params
    try
      parameters(params).route processOrArgv, config, callback
    catch err
      callback err
      
