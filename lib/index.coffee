
parameters = require 'parameters'
params = require './params'
load = require './config/load'
normalize = require './config/normalize'
store = require './config/store'
merge = require './utils/merge'

orgparams = parameters(merge {}, params, main: name: 'main').parse()

# Read configuration
load orgparams.config, (err, config) ->
  # Normalize coniguration
  config = normalize config
  # Enrich configuration with command discovery
  for command in store(config).commands()
    params.commands.push 
      name: command
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
  # config.params = parameters(params).parse()
  parameters(params).run(process, config)
