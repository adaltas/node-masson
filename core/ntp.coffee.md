
# NTP

Network Time Protocol (NTP) is a networking protocol for clock synchronization
between computer systems over packet-switched, variable-latency data networks.

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/yum'

## Configuration

The NTP module defined 2 properties:

*   `ntp.servers` (array or string)
    List the ntp servers used for synchronization.
*   `ntp.lag` (int)
    The tolerate time difference between the local and remote date untill which
    the module force a synchronization with `ntpdate`, default to 2000
    milliseconds.


Example:

```json
{
  "ntp": {
    "servers": "pool.ntp.org",
    "lag": 2000
  }
}
```

    exports.configure = (ctx) ->
      ntp = ctx.config.ntp ?= {}
      ntp.servers ?= []
      ntp.servers = ctx.config.ntp.servers.split(',') if typeof ctx.config.ntp.servers is 'string'
      ntp.lag ?= 2000
      ntp.fudge ?= false
      ntp.fudge = if ctx.config.host in ntp.servers then 10 else 14

## Install

The installation respect the procedure published on [cyberciti][cyberciti]. The
"ntp" server is installed as a startup service and `ntpdate` is run a first
time when the `ntpd` daemon isnt yet started.

    exports.push header: 'NTP # Install', timeout: -1, handler: ->
      {servers} = @config.ntp
      @service
        name: 'ntp'
        chk_name: 'ntpd'
        startup: true
      # Note, no NTPD server may be available yet, no solution at the moment
      # to wait for an available NTPD server
      @execute
        cmd: "ntpdate #{servers[0]}"
        if: ->
          @status -1 and servers?.length and servers[0] isnt @config.host

## Configure

The configuration file "/etc/ntp.conf" is updated with the list of servers
defined by the "ntp.servers" property. The "ntp" service is restarted if any
change to this file is detected.
The "fudge" property is used when a server should trust its own BIOS clock.
It should only be used in a pure offline configuration,
and when only ONE ntp server is configured

    exports.push header: 'NTP # Configure', handler: (_, callback) ->
      {ntp} = @config
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
          if_not: modified
        .then callback

## Start

Start the `ntpd` daemon if it isnt yet running.

    exports.push header: 'NTP # Start', label_true: 'STARTED', timeout: -1, handler: (options) ->
      options.log "Start the NTP service"
      @service_start
        name: 'ntpd'

## Check

This action compare the date on the remote server with the one where Masson is
being exectued. If the gap is greater than the one defined by the "ntp.lag"
property, the `ntpd` daemon is stop, the `ntpdate` command is used to
synchronization the date and the `ntpd` daemon is finally restarted.

    exports.push
      header: 'NTP # Check'
      label_true: 'CHECKED'
      not_if: [
         -> @config.ntp.servers[0] is @config.host
         -> @config.ntp.servers.length is 0
         -> @config.ntp.lag < 1
      ]
      handler: (options) ->
        # Here's good place to compare the date, maybe with the host maching:
        # if gap is greather than threehold, stop ntpd, ntpdate, start ntpd
        options.log "Synchronize the system clock with #{@config.ntp.servers[0]}"
        {lag} = @config.ntp
        current_lag = null
        @execute
          cmd: "date +%s"
        , (err, executed, stdout) ->
          throw err if err
          time = parseInt(stdout.trim(), 10) * 1000
          current_lag = Math.abs(new Date() - new Date(time))
        .call ->
          options.log "Lag greater than #{lag}ms: #{current_lag}"
          @service_stop
            name: 'ntpd'
            if: current_lag < lag
          @execute
            cmd: "ntpdate #{@config.ntp.servers[0]}"
            if: current_lag < lag
          @service_start
            name: 'ntpd'
            if: current_lag < lag

## Module Dependencies

    string = require 'mecano/lib/misc/string'

## Server configuration

This isnt (yet) supported. Add the following lines manually to the NTP
configuration file and restart the service.

```
server 127.127.1.0
fudge 127.127.1.0 stratum 10
restrict default nomodify nopeer notrap
restrict 127.0.0.1 mask 255.0.0.0
```

## Note

Upon execution of this module, the command `ntpq -p` should print:

```
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
+ntp1.domain.com     192.168.0.170     5 u   15  256  377    0.400   -2.950   3.127
*ntp2.domain.com     192.168.0.178     5 u  213  256  377    0.391   -2.409   2.785
```

[cyberciti]: http://www.cyberciti.biz/faq/howto-install-ntp-to-synchronize-server-clock/
