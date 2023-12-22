
import {shell} from 'shell'
import params from 'masson/params'
import load from 'masson/config/load'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'
import {merge, mutate} from 'mixme'

export default (processOrArgv) ->
  throw Error 'Required Argument: process or arguments is not provided' unless processOrArgv
  # Parse the first part of the arguments, without the user command
  orgparams = shell(merge params, main: name: 'main').parse(processOrArgv)
  # Read configuration
  config = await load orgparams.config
  # Normalize configuration
  config = normalize config
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
          description: 'Resume from previous run'    # Merge default shell with discovered shell and user shell
  mutate params, commands: 'clusters': commands: commands, config.params
  await shell(params).route processOrArgv, config
      
