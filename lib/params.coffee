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
      name: 'hosts', shortcut: 'h'
      description: 'Limit to a list of server hostnames'
    ]
  ,
  name: 'configure',
  description: 'Export in a file the server\'s configuration ',
  options: [
    name: 'output', shortcut: 'o', type: 'string'
    description: 'Name of the output file'
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
