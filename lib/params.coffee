
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
      run: 'masson/lib/commands/help'
    # 'help':
    #   description: 'Print this help and exit'
    #   run: 'masson/lib/commands/help'
    #   main:
    #     name: 'name'
    #     description: 'Print the help relative to the command'
      # help: true
    'pki':
      description: 'Certificate Management for development usage'
      run: 'masson/lib/commands/pki'
      options: [
        name: 'dir', shortcut: 'd', type: 'string'
        required: true
        description: 'Output directory'
      ]
      command: 'action'
      commands:
        'ca':
          description: 'Generate the Certificate Authority'
        'cacert-view':
          description: 'Display detailed information of a certificate'
        'check':
          description: 'Validate the certificate against the authority'
          main:
            name: 'fqdn'
            required: true
            description: 'The FQDN associated with the certificate'
        'cert':
          description: "Generate the private and public key pair for a given FQDN"
          run: 'masson/lib/commands/pki'
          main:
            name: 'fqdn'
            required: true
            description: 'The FQDN associated with the certificate'
        'cert-view':
          description: 'Display detailed information of a certificate'
          run: 'masson/lib/commands/pki'
          main:
            name: 'fqdn'
            description: 'The FQDN associated with the certificate'
    'secrets':
      description: 'Interact with the secure secret file store'
      run: 'masson/lib/commands/secrets'
      options: [
        name: 'store', shortcut: 's', type: 'string'
        default: '.secrets'
        description: 'File storing the secrets'
      ,
        name: 'envpw', shortcut: 'e', type: 'string'
        default: 'MASSON_SECRET_PW'
        description: 'Environment variable storing the password'
      ]
      command: 'action'
      commands:
        'init':
          description: 'Initialize the secret store'
        'unset':
          description: 'Delete a secret from the store'
          main:
            name: 'property'
            required: true
            description: 'Property name'
        'get':
          description: 'Get a secret'
          main:
            name: 'property'
            required: true
            description: 'Property name'
        'set':
          description: 'Set a secret'
          main:
            name: 'property'
            description: 'Property name'
          options:
            overwrite:
              type: 'boolean'
              shortcut: 'o'
              default: false
              description: 'Overwrite an existing property'
        'show':
          description: 'Display all the secrets'
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
      command: 'action'
      commands:
        'start':
          description: 'Start the server'
          options:
            'directory':
              description: 'Directory to serve'
              default: '../ryba-repos/public'
              shortcut: 'd'
            'pidfile':
              description: 'File storing the process ID'
              default: './conf/server.pid'
            'port':
              description: 'Port used by the server'
              default: 5680
              shortcut: 'p'
              type: 'integer'
        'stop':
          description: 'Stop the server'
          options:
            'port':
              description: 'Port used by the server'
              default: 5680
              shortcut: 'p'
              type: 'integer'
            'directory':
              description: 'Directory to serve'
              default: '../ryba-repos/public'
              shortcut: 'd'
            'pidfile':
              description: 'File storing the process ID'
              default: './conf/server.pid'
        'status':
          description: 'Is the server running?'
          options:
            'pidfile':
              description: 'File storing the process ID'
              default: './conf/server.pid'
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
