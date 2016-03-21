
## Install

The installation respect the procedure published on [cyberciti][cyberciti]. The
"ntp" server is installed as a startup service and `ntpdate` is run a first
time when the `ntpd` daemon isnt yet started.

    module.exports = header: 'NTP Install', timeout: -1, handler: ->
      {ntp} = @config
      @service
        header: 'Package'
        name: 'ntp'
        chk_name: 'ntpd'
        startup: true
        code_stopped: [1, 3]
      # Note, no NTPD server may be available yet, no solution at the moment
      # to wait for an available NTPD server
      @execute
        header: 'Synchronize'
        cmd: "ntpdate #{ntp.servers[0]}"
        if: ->
          @status -1 and ntp.servers?.length and ( ntp.servers[0] isnt @config.host )

## Configure

The configuration file "/etc/ntp.conf" is updated with the list of servers
defined by the "ntp.servers" property. The "ntp" service is restarted if any
change to this file is detected.
The "fudge" property is used when a server should trust its own BIOS clock.
It should only be used in a pure offline configuration,
and when only ONE ntp server is configured

      @call header: 'Configure', handler: (_, callback) ->
        servers = ntp.servers.slice 0
        return callback() unless servers?.length
        if @config.host in servers
          servers = servers.filter (e) => e isnt @config.host
        servers.push '127.127.1.0' if ntp.fudge
        @fs.readFile '/etc/ntp.conf', 'ascii', (err, content) =>
          return callback err if err
          lines = string.lines content
          modified = false
          position = 0
          #The fudge property is only appliable on NTP servers
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
              if commented and ntp.fudge
                lines[i] = "fudge #{opts}"
                modified = true
              else if not commented and not ntp.fudge
                lines[i] = "#fudge #{opts}"
                modified = true
          for server in servers
            if server not in found
              lines.splice position+1, 0, "server #{server} iburst"
              position++
              modified = true
          if ntp.fudge and not found_fudge
            lines.splice position+1, 0, "fudge 127.127.1.0 stratum #{ntp.fudge}"
            position++
            modified = true
          return callback null, false unless modified
          @write
            destination: '/etc/ntp.conf'
            content: lines.join('\n')
            backup: true
          @service
            srv_name: 'ntpd'
            action: 'restart'
            code_stopped: [1, 3]
            if_not: modified
          @then callback

## Module Dependencies

    string = require 'mecano/lib/misc/string'
