parameters = require 'parameters'

module.exports = parameters
  name: 'masson'
  description: 'Cluster deployment and management'
  options: [
    name: 'config', shortcut: 'c', type: 'array'
    description: 'One or multiple configuration files'
    required: true
  ,
    name: 'debug', shortcut: 'd', type: 'boolean'
    description: 'Print readable stacktrace'
  ]
  commands: [
    name: 'help'
    description: "Print this help and exit"
    main:
      name: 'subcommand'
      description: 'Print the help relative to the command'
  ,
    name: 'exec'
    description: "Distribute a shell command"
    main:
      name: 'subcommand'
      description: 'The subcommand to execute'
    options: [
      name: 'hosts', shortcut: 'h', type: 'array'
      description: 'Limit to a list of server hostnames'
    ]
  ,
  name: 'configure',
  description: 'Export servers\' configuration in a file',
  options: [
    name: 'output', shortcut: 'o', type: 'string'
    description: 'output directory'
  ,
    name: 'format', shortcut: 'f', type: 'string'
    description: 'Format of the output files: [json, cson, js, coffee]'
  ,
    name: 'hosts', shortcut: 'h', type: 'array'
    description: 'Limit to a list of server hostnames'
  ]
  ,
    name: 'tree'
    description: "Print the execution plan"
    options: [
      name: 'run', shortcut: 'r'
      description: 'Run list holding the list of modules'
      required: true
    ,
      name: 'host', shortcut: 'h'
      description: 'Server hostname associated with the plan'
      required: true
    ,
      name: 'modules', shortcut: 'm', type: 'array'
      description: 'Limit to a list of modules'
    ,
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ,
    name: 'server'
    description: "Print the execution plan"
    options: [
      name: 'action', shortcut: 'a'
      description: 'Run list holding the list of modules'
      one_of: ['start', 'stop', 'status']
      required: true
    ]
  ,
    name: 'prepare'
    description: 'Prepare components before deployment'
    options: [
      name: 'hosts', shortcut: 'h', type: 'array'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'modules', shortcut: 'm', type: 'array'
      description: 'Limit to a list of modules'
    ,
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ,
    name: 'init'
    description: 'Create a project with a default layout and configuration'
    options: [
      name: 'debug', shortcut: 'd', type: 'boolean'
      description: 'Print debug output'
    ,
      name: 'description', shortcut: 'i', type: 'string'
      description: 'Project description'
    ,
      name: 'latest', shortcut: 'l', type: 'boolean'
      description: 'Enable a development environment such as using latest git for package dependencies.'
    ,
      name: 'name', shortcut: 'n', type: 'string'
      description: 'Project name'
    ,
      name: 'path', shortcut: 'p', type: 'string'
      description: 'Path to the project directory, default to the current directory.'
    ]
  ,
    name: 'install'
    description: 'Install components and deploy configuration'
    options: [
      name: 'hosts', shortcut: 'h', type: 'array'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'modules', shortcut: 'm', type: 'array'
      description: 'Limit to a list of modules'
    ,
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ,
    name: 'start'
    description: 'Start server components'
    options: [
      name: 'hosts', shortcut: 'h', type: 'array'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'modules', shortcut: 'm', type: 'array'
      description: 'Limit to a list of modules'
    ,
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ,
    name: 'reload'
    description: 'Reload network sensitive components'
    options: [
      name: 'hosts', shortcut: 'h', type: 'array'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'modules', shortcut: 'm', type: 'array'
      description: 'Limit to a list of modules'
    ,
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ,
    name: 'status'
    description: 'Status of server components'
    options: [
      name: 'hosts', shortcut: 'h', type: 'array'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'modules', shortcut: 'm', type: 'array'
      description: 'Limit to a list of modules'
    ,
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ,
    name: 'stop',
    description: 'Stop server components'
    options: [
      name: 'hosts', shortcut: 'h', type: 'array'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'modules', shortcut: 'm', type: 'array'
      description: 'Limit to a list of modules'
    ,
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ,
    name: 'check',
    description: 'Check the servers',
    options: [
      name: 'hosts', shortcut: 'h', type: 'array'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'modules', shortcut: 'm', type: 'array'
      description: 'Limit to a list of modules'
    ,
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ,
    name: 'report',
    description: 'Print servers information',
    options: [
      name: 'hosts', shortcut: 'h', type: 'array'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'modules', shortcut: 'm', type: 'array'
      description: 'Limit to a list of modules'
    ,
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]

  ,
    name: 'clean'
    description: 'Clean the server'
    options: [
      name: 'hosts', shortcut: 'h', type: 'array'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'modules', shortcut: 'm', type: 'array'
      description: 'Limit to a list of modules'
    ,
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ,
    name: 'backup'
    description: 'Backup the server'
    options: [
      name: 'hosts', shortcut: 'h', type: 'array'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'modules', shortcut: 'm', type: 'array'
      description: 'Limit to a list of modules'
    ,
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ]
