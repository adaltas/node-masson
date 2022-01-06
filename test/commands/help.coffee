
normalize = require '../../lib/config/normalize'
params = require '../../lib/params'
fs = require('fs').promises
nikita = require 'nikita'
shell = require 'shell'

describe 'command help', ->
  
  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
      
  it 'print full help', ->
    write = process.stderr.write
    data = null
    process.stderr.write = (d)->
      data = d
      true
    await fs.writeFile "#{tmp}/a.json", JSON.stringify {}
    config = normalize
      clusters:
        'cluster_a':
          services:
            "#{tmp}/a": true
    shell(params).route(['help'], config)
    process.stderr.write = write
    data.should.eql """
    
    NAME
      masson - Cluster deployment and management.

    SYNOPSIS
      masson [masson options] <command>

    OPTIONS
      -c --config               One or multiple configuration files.
      -h --help                 Display help information
      -s --stacktrace           Print readable stacktrace.

    COMMANDS
      grpc                      Remote access through grpc.
      pki                       Certificate Management for development usage.
      secrets                   Interact with the secure secret file store.
      exec                      Distribute a shell command
      configure                 Export servers' configuration in a file.
      graph                     Print the execution plan
      server                    Print the execution plan
      init                      Create a project with a default layout and configuration
      help                      Display help information

    EXAMPLES
      masson --help             Show this message
      masson help               Show this message
    
    """
      
  it 'print help for command exec', ->
    write = process.stderr.write
    data = null
    process.stderr.write = (d)->
      data = d
      true
    await fs.writeFile "#{tmp}/a.json", JSON.stringify {}
    config = normalize
      clusters:
        'cluster_a':
          services:
            "#{tmp}/a": true
    shell(params).route(['help', 'exec'], config)
    process.stderr.write = write
    data.should.eql """

    NAME
      masson exec - Distribute a shell command

    SYNOPSIS
      masson [masson options] exec [exec options] {subcommand}

    OPTIONS for exec
         subcommand             The subcommand to execute.
      -h --help                 Display help information
      -n --nodes                Limit to a list of server FQDNs.
      -t --tags                 Limit to servers that honor a list of tags.

    OPTIONS for masson
      -c --config               One or multiple configuration files.
      -h --help                 Display help information
      -s --stacktrace           Print readable stacktrace.

    EXAMPLES
      masson exec --help        Show this message
    
    """
