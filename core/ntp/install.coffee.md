
# NTP Install

The installation follows the procedure published on [cyberciti][cyberciti]. The
"ntp" server is installed as a startup service and `ntpdate` is run a first
time when the `ntpd` daemon isnt yet started.

    export default header: 'NTP Install', handler: ({options}) ->

## Package

      @service
        header: 'Package'
        name: 'ntp'
        chk_name: 'ntpd'
        startup: true
        code_stopped: [1, 3]

## Configure

The configuration file "/etc/ntp.conf" is updated with the list of servers
defined by the "ntp.servers" property. The "ntp" service is restarted if any
change to this file is detected.
The "fudge" property is used when a server should trust its own BIOS clock.
It should only be used in a pure offline configuration,
and when only ONE ntp server is configured

      @call header: 'Configure', handler: (_, callback) ->
        servers = options.servers.slice 0
        return callback() unless servers?.length
        if options.fqdn in servers
          servers = servers.filter (fqdn) => fqdn isnt options.fqdn
        servers.push '127.127.1.0' if options.fudge
        ssh = @ssh options.ssh
        fs.readFile ssh, '/etc/ntp.conf', 'ascii', (err, content) =>
          return callback err if err
          lines = string.lines content
          modified = false
          position = 0
          # The fudge property is only applicable on NTP servers
          found = []
          found_fudge = false
          for line, i in lines
            if match = /^(#)?server\s+(\S+)(.*)$/.exec line
              position = i
              commented = match[1] is '#'
              host = match[2]
              opts = match[3]
              found.push host
              # if host is '127.127.1.0'
              #   local_server = host
              #   continue
              if commented and host in servers
                lines[i] = "server #{host}#{opts}"
                modified = true
              else if not commented and host not in servers
                lines[i] = "#server #{host}#{opts}"
                modified = true
            else if match = /^(#)?fudge\s+(.*)$/.exec line
              fudge_position = i
              commented = match[1] is '#'
              opts = match[2]
              found_fudge = true
              if commented and options.fudge
                lines[i] = "fudge #{opts}"
                modified = true
              else if not commented and not options.fudge
                lines[i] = "#fudge #{opts}"
                modified = true
          for server in servers
            if server not in found
              lines.splice position+1, 0, "server #{server} iburst"
              position++
              modified = true
          if options.fudge and not found_fudge
            lines.splice position+1, 0, "fudge 127.127.1.0 stratum #{options.fudge}"
            position++
            modified = true
          return callback null, false unless modified
          @file
            target: '/etc/ntp.conf'
            content: lines.join('\n')
            backup: true
          @service
            srv_name: 'ntpd'
            state: 'restarted'
            code_stopped: [1, 3]
            if_not: modified
          @next callback

## Synchronization

Note, no NTPD server may be available yet, no solution at the moment
to wait for an available NTPD server.

      @system.execute
        header: 'Synchronization'
        cmd: """
        lag=`ntpdate -q #{options.servers[0]} | head -n 1| sed 's/.*offset -*\\([0-9]*\\).*/\\1/'`
        [ "$lag" -gt "#{Math.round(options.lag/1000)}" ] || exit 3
        """
        code_skipped: 3
      @call if: (-> @status -1), ->
        @service.stop 'ntpd'
        @system.execute "ntpdate #{options.servers[0]}"
        @service.start 'ntpd'

## Module Dependencies

    fs = require 'ssh2-fs'
    string = require '@nikitajs/core/lib/misc/string'

[cyberciti]: http://www.cyberciti.biz/faq/howto-install-ntp-to-synchronize-server-clock/
