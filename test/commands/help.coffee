
import fs from 'node:fs/promises'
import { Writable } from 'node:stream'
import nikita from 'nikita'
import { shell } from 'shell'
import normalize from 'masson/config/normalize'
import params from 'masson/params'

describe 'command help', ->
      
  it 'print full help', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      data = null
      stderr = new Writable
        write: (d) -> data = d.toString()
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      config = await normalize
        clusters:
          'cluster_a':
            services:
              "#{tmpdir}/a.json": true
      await shell({...params, router: stderr: stderr}).route(['help'], config)
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
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      data = null
      stderr = new Writable
        write: (d) -> data = d.toString()
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      config = await normalize
        clusters:
          'cluster_a':
            services:
              "#{tmpdir}/a.json": true
      await shell({...params, router: stderr: stderr}).route(['help', 'exec'], config)
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
