
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
  commands: [
    name: 'help'
    description: 'Print this help and exit'
    run: 'masson/lib/commands/help'
    main:
      name: 'subcommand'
      description: 'Print the help relative to the command'
  ,
    name: 'exec'
    description: "Distribute a shell command"
    run: 'masson/lib/commands/exec'
    main:
      name: 'subcommand'
      description: 'The subcommand to execute'
    options: [
      name: 'nodes', shortcut: 'n', type: 'array'
      description: 'Limit to a list of server FQDNs'
    ]
  ,
    name: 'configure'
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
  ,
    name: 'graph'
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
    # ,
    #   name: 'run', shortcut: 'r'
    #   description: 'Run list holding the list of modules'
    #   required: true
    # ,
    #   name: 'node', shortcut: 'n', type: 'string'
    #   description: 'Server FQDN associated with the plan'
    #   required: true
    # ,
    #   name: 'tags', shortcut: 't', type: 'array'
    #   description: 'Limit to servers that honor a list of tags'
    # ,
    #   name: 'modules', shortcut: 'm', type: 'array'
    #   description: 'Limit to a list of modules'
    ]
  ,
    name: 'server'
    description: 'Print the execution plan'
    run: 'masson/lib/commands/server'
    options: [
      name: 'action', shortcut: 'a'
      description: 'Run list holding the list of modules'
      one_of: ['start', 'stop', 'status']
      required: true
    ]
  ,
  #   name: 'prepare'
  #   description: 'Prepare components before deployment'
  #   run: 'masson/lib/commands/prepare'
  #   options: [
  #     name: 'nodes', shortcut: 'n', type: 'array'
  #     description: 'Limit to a list of server FQDNs'
  #   ,
  #     name: 'tags', shortcut: 't', type: 'array'
  #     description: 'Limit to servers that honor a list of tags'
  #   ,
  #     name: 'modules', shortcut: 'm', type: 'array'
  #     description: 'Limit to a list of modules'
  #   ]
  # ,
    name: 'init'
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
  ,
  #   name: 'install'
  #   description: 'Install components and deploy configuration'
  #   run: 'masson/lib/commands/run'
  #   options: [
  #     name: 'nodes', shortcut: 'n', type: 'array'
  #     description: 'Limit to a list of server FQDNs'
  #   ,
  #     name: 'tags', shortcut: 't', type: 'array'
  #     description: 'Limit to servers that honor a list of tags'
  #   ,
  #     name: 'modules', shortcut: 'm', type: 'array'
  #     description: 'Limit to a list of modules'
  #   ,
  #     name: 'resume', shortcut: 'r', type: 'boolean'
  #     description: 'Resumt from previous run'
  #   ]
  # ,
  #   name: 'start'
  #   description: 'Start server components'
  #   run: 'masson/lib/commands/run'
  #   options: [
  #     name: 'nodes', shortcut: 'n', type: 'array'
  #     description: 'Limit to a list of server FQDNs'
  #   ,
  #     name: 'tags', shortcut: 't', type: 'array'
  #     description: 'Limit to servers that honor a list of tags'
  #   ,
  #     name: 'modules', shortcut: 'm', type: 'array'
  #     description: 'Limit to a list of modules'
  #   ,
  #     name: 'resume', shortcut: 'r', type: 'boolean'
  #     description: 'Resumt from previous run'
  #   ]
  # ,
  #   name: 'reload'
  #   description: 'Reload network sensitive components'
  #   run: 'masson/lib/commands/run'
  #   options: [
  #     name: 'nodes', shortcut: 'n', type: 'array'
  #     description: 'Limit to a list of server FQDNs'
  #   ,
  #     name: 'tags', shortcut: 't', type: 'array'
  #     description: 'Limit to servers that honor a list of tags'
  #   ,
  #     name: 'modules', shortcut: 'm', type: 'array'
  #     description: 'Limit to a list of modules'
  #   ,
  #     name: 'resume', shortcut: 'r', type: 'boolean'
  #     description: 'Resumt from previous run'
  #   ]
  # ,
  #   name: 'status'
  #   description: 'Status of server components'
  #   run: 'masson/lib/commands/run'
  #   options: [
  #     name: 'nodes', shortcut: 'n', type: 'array'
  #     description: 'Limit to a list of server FQDNs'
  #   ,
  #     name: 'tags', shortcut: 't', type: 'array'
  #     description: 'Limit to servers that honor a list of tags'
  #   ,
  #     name: 'modules', shortcut: 'm', type: 'array'
  #     description: 'Limit to a list of modules'
  #   ,
  #     name: 'resume', shortcut: 'r', type: 'boolean'
  #     description: 'Resumt from previous run'
  #   ]
  # ,
  #   name: 'stop',
  #   description: 'Stop server components'
  #   run: 'masson/lib/commands/run'
  #   options: [
  #     name: 'nodes', shortcut: 'n', type: 'array'
  #     description: 'Limit to a list of server FQDNs'
  #   ,
  #     name: 'tags', shortcut: 't', type: 'array'
  #     description: 'Limit to servers that honor a list of tags'
  #   ,
  #     name: 'modules', shortcut: 'm', type: 'array'
  #     description: 'Limit to a list of modules'
  #   ,
  #     name: 'resume', shortcut: 'r', type: 'boolean'
  #     description: 'Resumt from previous run'
  #   ]
  # ,
  #   name: 'check',
  #   description: 'Check the servers'
  #   run: 'masson/lib/commands/run'
  #   options: [
  #     name: 'nodes', shortcut: 'n', type: 'array'
  #     description: 'Limit to a list of server FQDNs'
  #   ,
  #     name: 'tags', shortcut: 't', type: 'array'
  #     description: 'Limit to servers that honor a list of tags'
  #   ,
  #     name: 'modules', shortcut: 'm', type: 'array'
  #     description: 'Limit to a list of modules'
  #   ,
  #     name: 'resume', shortcut: 'r', type: 'boolean'
  #     description: 'Resumt from previous run'
  #   ]
  # ,
  #   name: 'report',
  #   description: 'Print servers information'
  #   run: 'masson/lib/commands/run'
  #   options: [
  #     name: 'nodes', shortcut: 'n', type: 'array'
  #     description: 'Limit to a list of server FQDNs'
  #   ,
  #     name: 'tags', shortcut: 't', type: 'array'
  #     description: 'Limit to servers that honor a list of tags'
  #   ,
  #     name: 'modules', shortcut: 'm', type: 'array'
  #     description: 'Limit to a list of modules'
  #   ,
  #     name: 'resume', shortcut: 'r', type: 'boolean'
  #     description: 'Resumt from previous run'
  #   ]
  # ,
  #   name: 'clean'
  #   description: 'Clean the server'
  #   run: 'masson/lib/commands/run'
  #   options: [
  #     name: 'nodes', shortcut: 'n', type: 'array'
  #     description: 'Limit to a list of server FQDNs'
  #   ,
  #     name: 'tags', shortcut: 't', type: 'array'
  #     description: 'Limit to servers that honor a list of tags'
  #   ,
  #     name: 'modules', shortcut: 'm', type: 'array'
  #     description: 'Limit to a list of modules'
  #   ,
  #     name: 'resume', shortcut: 'r', type: 'boolean'
  #     description: 'Resumt from previous run'
  #   ]
  # ,
  #   name: 'backup'
  #   description: 'Backup the server'
  #   run: 'masson/lib/commands/run'
  #   options: [
  #     name: 'nodes', shortcut: 'n', type: 'array'
  #     description: 'Limit to a list of server FQDNs'
  #   ,
  #     name: 'tags', shortcut: 't', type: 'array'
  #     description: 'Limit to servers that honor a list of tags'
  #   ,
  #     name: 'modules', shortcut: 'm', type: 'array'
  #     description: 'Limit to a list of modules'
  #   ,
  #     name: 'resume', shortcut: 'r', type: 'boolean'
  #     description: 'Resumt from previous run'
  #   ]
  # ,
  #   name: 'benchmark'
  #   description: 'Run benchmark modules'
  #   run: 'masson/lib/commands/run'
  #   options: [
  #     name: 'nodes', shortcut: 'n', type: 'array'
  #     description: 'Limit to a list of server FQDNs'
  #   ,
  #     name: 'tags', shortcut: 't', type: 'array'
  #     description: 'Limit to servers that honor a list of tags'
  #   ,
  #     name: 'modules', shortcut: 'm', type: 'array'
  #     description: 'Limit to a list of modules'
  #   ,
  #     name: 'resume', shortcut: 'r', type: 'boolean'
  #     description: 'Resumt from previous run'
  #   ]
  # ,
  #   name: 'ambari_blueprint'
  #   description: 'Export blueprint definitions'
  #   run: 'masson/lib/commands/run'
  #   options: [
  #     name: 'nodes', shortcut: 'n', type: 'array'
  #     description: 'Limit to a list of server FQDNs'
  #   ,
  #     name: 'tags', shortcut: 't', type: 'array'
  #     description: 'Limit to servers that honor a list of tags'
  #   ,
  #     name: 'modules', shortcut: 'm', type: 'array'
  #     description: 'Limit to a list of modules'
  #   ,
  #     name: 'resume', shortcut: 'r', type: 'boolean'
  #     description: 'Resumt from previous run'
  #   ]
  ]
