
normalize = require '../../lib/config/normalize'
params = require '../../lib/params'
fs = require 'fs'
nikita = require 'nikita'
parameters = require 'parameters'

describe 'command help', ->
  
  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
    nikita
    .system.mkdir target: tmp
    .promise()
  afterEach ->
    nikita
    .system.remove tmp
    .promise()
      
  it 'print full help', ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
      true
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    config = normalize
      clusters:
        'cluster_a':
          services:
            "#{tmp}/a": true
    parameters(params).run(['help'], config)
    process.stdout.write = write
    data.should.eql """
    NAME
        masson - Cluster deployment and management
    SYNOPSIS
        masson command [options...]
        where command is one of
          help              Print this help and exit
          exec              Distribute a shell command
          configure         Export servers' configuration in a file
          graph             Print the execution plan
          server            Print the execution plan
          init              Create a project with a default layout and configuration
    DESCRIPTION
        -c --config         One or multiple configuration files
        -d --debug          Print readable stacktrace
        help                Print this help and exit
          subcommand          Print the help relative to the command
        exec                Distribute a shell command
          -n --nodes          Limit to a list of server FQDNs
          subcommand          The subcommand to execute
        configure           Export servers' configuration in a file
          -o --output         output directory
          -f --format         Format of the output files: [json, cson, js, coffee]
          -n --nodes          Print configuration of nodes
          -c --cluster        Print configuration of clusters
          --clusters          Print list of cluster names
          -s --service        Print configuration of a services (format cluster:service)
          --service_names     Print list of service names
        graph               Print the execution plan
          -o --output         output directory
          -f --format         Format of the output files: [json, cson, js, coffee]
          -n --nodes          Print nodes information
        server              Print the execution plan
          -a --action         Run list holding the list of modules
          -p --port           Port used by the server
          -d --directory      Directory to serve
          --pidfile           File storing the process ID
        init                Create a project with a default layout and configuration
          -d --debug          Print debug output
          -i --description    Project description
          -l --latest         Enable a development environment such as using latest git for package dependencies.
          -n --name           Project name
          -p --path           Path to the project directory, default to the current directory.
    EXAMPLES
        masson help         Show this message
    
    """
      
  it 'print help for command exec', ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
      true
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    config = normalize
      clusters:
        'cluster_a':
          services:
            "#{tmp}/a": true
    parameters(params).run(['help', 'exec'], config)
    process.stdout.write = write
    data.should.eql """
    NAME
        masson exec - Distribute a shell command
    SYNOPSIS
        masson exec [options...] [subcommand]
    DESCRIPTION
        exec                Distribute a shell command
          -n --nodes          Limit to a list of server FQDNs
          subcommand          The subcommand to execute
    
    """
