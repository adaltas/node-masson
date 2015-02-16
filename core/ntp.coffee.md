
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

    exports.push (ctx) ->
      ntp = ctx.config.ntp ?= {}
      ntp.servers ?= []
      ntp.servers = ctx.config.ntp.servers.split(',') if typeof ctx.config.ntp.servers is 'string'
      ntp.lag ?= 2000
      ntp.fudge ?= false
      # ntp.fudge = ctx.config.host if ntp.fudge is true

## Install

The installation respect the procedure published on [cyberciti][cyberciti]. The
"ntp" server is installed as a startup service and `ntpdate` is run a first 
time when the `ntpd` daemon isnt yet started.

    exports.push name: 'NTP # Install', timeout: -1, handler: (ctx, next) ->
      {servers} = ctx.config.ntp
      ctx.service
        name: 'ntp'
        chk_name: 'ntpd'
        startup: true
      , (err, serviced) ->
        return next err if err
        return next null, false unless serviced
        return next null, false unless servers?.length
        ctx.execute
          cmd: "ntpdate #{servers[0]}"
          if: servers[0] isnt ctx.config.host
        , (err) ->
          next err, true

## Configure

The configuration file "/etc/ntp.conf" is updated with the list of servers 
defined by the "ntp.servers" property. The "ntp" service is restarted if any
change to this file is detected.
The "fudge" property is used when a server should trust its own BIOS clock.
It should only be used in a pure offline configuration,
and when only ONE ntp server is configured

    exports.push name: 'NTP # Configure', handler: (ctx, next) ->
      {servers, fudge} = ctx.config.ntp
      return next() unless servers?.length
      ctx.fs.readFile '/etc/ntp.conf', 'ascii', (err, content) ->
        return next err if err
        lines = string.lines content
        modified = false
        position = 0
        # local_server = null

The fudge property is only appliable on NTP servers

        fudge = fudge and ctx.config.host in servers
        servers.push '127.127.1.0' if fudge and '127.127.1.0' not in servers
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
            if commented and fudge
              lines[i] = "fudge #{opts}"
              modified = true
            else if not commented and not fudge
              lines[i] = "#fudge #{opts}"
              modified = true
        for server in servers
          if server not in found
            lines.splice position+1, 0, "server #{server} iburst"
            position++
            modified = true
        if fudge and not found_fudge
          lines.splice position+1, 0, "fudge 127.127.1.0 stratum 10"
          position++
          modified = true
        return next null, false unless modified
        ctx.fs.writeFile '/etc/ntp.conf', lines.join('\n'), (err) ->
          return next err if err
          ctx.service
            srv_name: 'ntpd'
            action: 'restart'
          , (err) ->
            next err, true
      # write = []
      # write.push
      #   match: /^(server [\d]+.*$)/mg
      #   replace: "#$1"
      # for server in servers
      #   write.push
      #     match: new RegExp "^server #{quote server}.*$", 'mg'
      #     replace: "server #{server} iburst"
      #     append: 'Please consider joining'
      # ctx.write
      #   destination: '/etc/ntp.conf'
      #   write: write
      #   backup: true
      # , (err, written) ->
      #   return next err if err
      #   return next null, false unless written
      #   ctx.service
      #     name: 'ntp'
      #     srv_name: 'ntpd'
      #     action: 'restart'
      #   , next

## Start

Start the `ntpd` daemon if it isnt yet running.

    exports.push name: 'NTP # Start', timeout: -1, handler: (ctx, next) -> 
      ctx.log "Start the NTP service"
      ctx.service
        srv_name: 'ntpd'
        action: 'start'
      , next

## Check

This action compare the date on the remote server with the one where Masson is
being exectued. If the gap is greater than the one defined by the "ntp.lag"
property, the `ntpd` daemon is stop, the `ntpdate` command is used to 
synchronization the date and the `ntpd` daemon is finally restarted.

    exports.push name: 'NTP # Check', handler: (ctx, next) ->
      # Here's good place to compare the date, maybe with the host maching:
      # if gap is greather than threehold, stop ntpd, ntpdate, start ntpd
      return next() if ctx.config.ntp.servers[0] is ctx.config.host
      return next() if ctx.config.ntp.servers.length is 0
      ctx.log "Synchronize the system clock with #{ctx.config.ntp.servers[0]}"
      {lag} = ctx.config.ntp
      return next() if lag < 1
      ctx.execute
        cmd: "date +%s"
      , (err, executed, stdout) ->
        return next err if err
        time = parseInt(stdout.trim(), 10) * 1000
        current_lag = Math.abs(new Date() - new Date(time))
        return next null, false if current_lag < lag
        ctx.log "Lag greater than #{lag}ms: #{current_lag}"
        ctx.service
          srv_name: 'ntpd'
          action: 'stop'
        , (err, serviced) ->
          return next err if err
          ctx.execute
            cmd: "ntpdate #{ctx.config.ntp.servers[0]}"
          , (err) ->
            return next err if err
            ctx.service
              srv_name: 'ntpd'
              action: 'start'
            , next

## Module Dependencies

    quote = require 'regexp-quote'
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

