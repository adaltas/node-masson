parameters = require 'parameters'

module.exports = parameters
  name: 'big'
  description: 'Hadoop cluster management'
  options: [
    name: 'config', shortcut: 'c'
    description: 'Configuration file'
    required: true
  , 
    name: 'debug', shortcut: 'd', type: 'boolean'
    description: 'Print readable stacktrace'
  ]
  action: 'command'
  actions: [
    name: 'help'
    main: name: 'subcommand'
  ,
    name: 'exec'
    main: name: 'subcommand'
  ,
    name: 'tree'
    options: [
      name: 'run', shortcut: 'r'
      description: 'Run list holding the list of modules'
      required: true
    ,
      name: 'host', shortcut: 'h'
      description: 'Limit to a list of server hostnames'
      required: true
    ,
      name: 'modules', shortcut: 'm'
      description: 'Limit to a list of modules'
    , 
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ,
    name: 'install'
    description: 'Install components and deploy configuration'
    options: [
      name: 'hosts', shortcut: 'h'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
    ,
      name: 'modules', shortcut: 'm'
      description: 'Limit to a list of modules'
    , 
      name: 'fast', shortcut: 'f', type: 'boolean'
      description: 'Fast mode without dependency resolution'
    ]
  ,
    name: 'start'
    description: 'Start server components'
    options: [
      name: 'hosts', shortcut: 'h'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
    ,
      name: 'modules', shortcut: 'm'
      description: 'Limit to a list of modules'
    ]
  ,
    name: 'reload'
    description: 'Start server components'
    options: [
      name: 'hosts', shortcut: 'h'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
    ,
      name: 'modules', shortcut: 'm'
      description: 'Limit to a list of modules'
    ]
  ,
    name: 'stop',
    description: 'Stop server components'
    options: [
      name: 'hosts', shortcut: 'h'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
    ,
      name: 'modules', shortcut: 'm'
      description: 'Limit to a list of modules'
    ]
  ,
    name: 'check',
    description: 'Check the server',
    options: [
      name: 'hosts', shortcut: 'h'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
    ,
      name: 'modules', shortcut: 'm'
      description: 'Limit to a list of modules'
    ]
  ,
    name: 'clean'
    description: 'Clean the server'
    options: [
      name: 'hosts', shortcut: 'h'
      description: 'Limit to a list of server hostnames'
    ,
      name: 'roles', shortcut: 'r'
      description: 'Limit to a list of roles'
    ,
      name: 'modules', shortcut: 'm'
      description: 'Limit to a list of modules'
    ]
  ]

