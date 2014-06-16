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
  action: 'command'
  actions: [
    name: 'help'
    main:
      name: 'subcommand'
      description: 'Print the help relative to the command'
    description: "Print this help and exit"
  ,
    name: 'exec'
    main:
      name: 'subcommand'
      description: 'The subcommand to execute'
    description: "Distribute a shell command"
  ,
    name: 'tree'
    description: "Print the execution plan"
    options: [
      name: 'run', shortcut: 'r'
      description: 'Run list holding the list of modules'
      required: true
    ,
      name: 'host', shortcut: 'h'
      description: 'Limit to a list of server hostnames'
      required: true
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
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
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
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
    ,
      name: 'modules', shortcut: 'm', type: 'array'
      description: 'Limit to a list of modules'
    , 
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ,
    name: 'reload'
    description: 'Start server components'
    options: [
      name: 'hosts', shortcut: 'h', type: 'array'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
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
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
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
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
    ,
      name: 'modules', shortcut: 'm', type: 'array'
      description: 'Limit to a list of modules'
    , 
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ,
    name: 'check',
    description: 'Check the server',
    options: [
      name: 'hosts', shortcut: 'h', type: 'array'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
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
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
    ,
      name: 'modules', shortcut: 'm', type: 'array'
      description: 'Limit to a list of modules'
    , 
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ]

