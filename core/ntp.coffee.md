---
title: NTP
module: masson/core/ntp
layout: module
---

# NTP

Network Time Protocol (NTP) is a networking protocol for clock synchronization 
between computer systems over packet-switched, variable-latency data networks.

    quote = require 'regexp-quote'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/yum'

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

    module.exports.push (ctx) ->
      ctx.config.ntp ?= {}
      ctx.config.ntp.servers ?= ['pool.ntp.org']
      ctx.config.ntp.servers = [ctx.config.ntp.servers] if typeof ctx.config.ntp.servers is 'string'
      ctx.config.ntp.lag ?= 2000


## Install

The installation respect the procedure published on [cyberciti][cyberciti]. The
"ntp" server is installed as a startup service and `ntpdate` is run a first 
time when the `ntpd` daemon isnt yet started.

    module.exports.push name: 'NTP # Install', timeout: -1, callback: (ctx, next) -> 
      ctx.log 'Install the NTP service and turn on the service'
      return next() unless ctx.config.ntp.servers?.length
      ctx.service
        name: 'ntp'
        chk_name: 'ntpd'
        startup: true
      , (err, serviced) ->
        return next err if err
        return next null, ctx.PASS unless serviced
        ctx.execute
          cmd: "ntpdate #{ctx.config.ntp.servers[0]}"
          if: ctx.config.ntp.servers[0] isnt ctx.config.host
        , (err) ->
          next err, ctx.OK

## Configure

The configuration file "/etc/ntp.conf" is updated with the list of servers 
defined by the "ntp.servers" property. The "ntp" service is restarted if any
change to this file is detected.

    module.exports.push name: 'NTP # Configure', callback: (ctx, next) ->
      write = []
      write.push
        match: /^(server [\d]+.*$)/mg
        replace: "#$1"
      for server in ctx.config.ntp.servers
        write.push
          match: new RegExp "^server #{quote server}.*$", 'mg'
          replace: "server #{server} iburst"
          append: 'Please consider joining'
      ctx.write
        destination: '/etc/ntp.conf'
        write: write
        backup: true
      , (err, written) ->
        return next err if err
        return next null, ctx.PASS unless written
        ctx.service
          name: 'ntp'
          srv_name: 'ntpd'
          action: 'restart'
        , (err) ->
          next err, ctx.OK

## Start

Start the `ntpd` daemon if it isnt yet running.

    module.exports.push name: 'NTP # Start', timeout: -1, callback: (ctx, next) -> 
      ctx.log "Start the NTP service"
      ctx.service
        name: 'ntp'
        srv_name: 'ntpd'
        action: 'start'
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

## Check

This action compare the date on the remote server with the one where Masson is
being exectued. If the gap is greater than the one defined by the "ntp.lag"
property, the `ntpd` daemon is stop, the `ntpdate` command is used to 
synchronization the date and the `ntpd` daemon is finally restarted.

    module.exports.push name: 'NTP # Check', callback: (ctx, next) ->
      # Here's good place to compare the date, maybe with the host maching:
      # if gap is greather than threehold, stop ntpd, ntpdate, start ntpd
      return next() if ctx.config.ntp.servers[0] is ctx.config.host
      ctx.log "Synchronize the system clock with #{ctx.config.ntp.servers[0]}"
      {lag} = ctx.config.ntp
      return next null, ctx.INAPPLICABLE if lag < 1
      ctx.execute
        cmd: "date +%s"
      , (err, executed, stdout) ->
        return next err if err
        time = parseInt(stdout.trim(), 10) * 1000
        current_lag = Math.abs(new Date() - new Date(time))
        return next null, ctx.PASS if current_lag < lag
        ctx.log "Lag greater than #{lag}ms: #{current_lag}"
        ctx.service
          name: 'ntp'
          srv_name: 'ntpd'
          action: 'stop'
        , (err, serviced) ->
          return next err if err
          ctx.execute
            cmd: "ntpdate #{ctx.config.ntp.servers[0]}"
          , (err) ->
            return next err if err
            ctx.service
              name: 'ntp'
              srv_name: 'ntpd'
              action: 'stop'
            , (err, serviced) ->
              next err, ctx.OK

## Note

Upon execution of this module, the command `ntpq -p` should print:

```
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
+ntp1.domain.com     192.168.0.170     5 u   15  256  377    0.400   -2.950   3.127
*ntp2.domain.com     192.168.0.178     5 u  213  256  377    0.391   -2.409   2.785
```

[cyberciti]: http://www.cyberciti.biz/faq/howto-install-ntp-to-synchronize-server-clock/

