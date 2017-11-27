
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
        masson [masson options] <command>

    OPTIONS
        -c --config             One or multiple configuration files Required.
        -d --debug              Print readable stacktrace
        -h --help               Display help information

    COMMANDS
        help                    Display help information about masson
        pki                     Certificate Management for development usage
        exec                    Distribute a shell command
        configure               Export servers' configuration in a file
        graph                   Print the execution plan
        server                  Print the execution plan
        init                    Create a project with a default layout and configuration

    COMMAND "help"
        help                    Display help information about masson
        help {name}             Help about a specific command

    COMMAND "pki"
        pki [pki options] <action>
        Where command is one of ca, cacert-view, check, cert, cert-view.

    COMMAND "exec"
        exec                    Distribute a shell command
        exec {subcommand}       The subcommand to execute

    COMMAND "configure"
        configure               Export servers' configuration in a file

    COMMAND "graph"
        graph                   Print the execution plan

    COMMAND "server"
        server [server options] <action>
        Where command is one of start, stop, status.

    COMMAND "init"
        init                    Create a project with a default layout and configuration

    EXAMPLES
        masson --help           Show this message
        masson help             Show this message
    
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
        masson [masson options] exec [exec options] {subcommand}

    OPTIONS for exec
        -n --nodes              Limit to a list of server FQDNs
        -h --help               Display help information
        subcommand              The subcommand to execute

    OPTIONS for masson
        -c --config             One or multiple configuration files Required.
        -d --debug              Print readable stacktrace
        -h --help               Display help information

    EXAMPLES
        masson exec --help      Show this message
    
    """
