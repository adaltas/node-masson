
module.exports =
  name: 'masson'
  description: 'Cluster deployment and management'
  load: require './utils/load'
  options: [
    name: 'config', shortcut: 'c', type: 'array'
    description: 'One or multiple configuration files'
    required: true
  ,
    name: 'debug', shortcut: 'd', type: 'boolean'
    description: 'Print readable stacktrace'
  ]
  commands:
    'help':
      description: 'Print this help and exit'
      run: 'masson/lib/commands/help'
      main:
        name: 'subcommand'
        description: 'Print the help relative to the command'
    'exec':
      description: "Distribute a shell command"
      run: 'masson/lib/commands/exec'
      main:
        name: 'subcommand'
        description: 'The subcommand to execute'
      options: [
        name: 'nodes', shortcut: 'n', type: 'array'
        description: 'Limit to a list of server FQDNs'
      ]
    'configure':
      description: 'Export servers\' configuration in a file'
      run: 'masson/lib/commands/configure'
      options: [
        name: 'output', shortcut: 'o', type: 'string'
        description: 'output directory'
      ,
        name: 'format', shortcut: 'f', type: 'string'
        description: 'Format of the output files: [json, cson, js, coffee]'
      ,
        name: 'nodes', shortcut: 'n', type: 'boolean'
        description: 'Print configuration of nodes'
      ,
        name: 'cluster', shortcut: 'c', type: 'string'
        description: 'Print configuration of clusters'
      ,
        name: 'clusters', type: 'boolean'
        description: 'Print list of cluster names'
      ,
        name: 'service', shortcut: 's', type: 'string'
        description: 'Print configuration of a services (format cluster:service)'
      ,
        name: 'service_names', type: 'boolean'
        description: 'Print list of service names'
      ]
    'graph':
      description: 'Print the execution plan'
      run: 'masson/lib/commands/graph'
      options: [
        name: 'output', shortcut: 'o', type: 'string'
        description: 'output directory'
      ,
        name: 'format', shortcut: 'f', type: 'string'
        description: 'Format of the output files: [json, cson, js, coffee]'
      ,
        name: 'nodes', shortcut: 'n', type: 'boolean'
        description: 'Print nodes information'
    ]
    'server':
      description: 'Print the execution plan'
      run: 'masson/lib/commands/server'
      options: [
        name: 'action', shortcut: 'a'
        description: 'Run list holding the list of modules'
        one_of: ['start', 'stop', 'status']
        required: true
      ,
        name: 'port', shortcut: 'p', type: 'integer'
        description: 'Port listening by the server'
        default: 5680
      ,
        name: 'port', shortcut: 'p'
        description: 'Port used by the server'
        default: 5680
      ,
        name: 'directory', shortcut: 'd'
        description: 'Directory to serve'
        default: '../ryba-repos/public'
      ,
        name: 'pidfile'
        description: 'File storing the process ID'
        default: './conf/server.pid'
      ]
    'init':
      description: 'Create a project with a default layout and configuration'
      run: 'masson/lib/commands/init'
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
