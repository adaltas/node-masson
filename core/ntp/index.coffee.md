
# NTP

Network Time Protocol (NTP) is a networking protocol for clock synchronization
between computer systems over packet-switched, variable-latency data networks.

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

    # Disable for now
    # exports.push 'masson/core/yum'

    module.exports = ->
      require('../../bootstrap/fs').call @
      ntp = @config.ntp ?= {}
      ntp.servers ?= []
      ntp.servers = @config.ntp.servers.split(',') if typeof @config.ntp.servers is 'string'
      ntp.lag ?= 2000
      ntp.fudge ?= false
      ntp.fudge = if @config.host in ntp.servers then 10 else 14
      'check':
        'masson/core/ntp/check'
      'install': [
        'masson/core/yum'
        'masson/core/ntp/install'
        'masson/core/ntp/start'
        'masson/core/ntp/check'
      ]
      'start':
        'masson/core/ntp/start'
      'stop':
        'masson/core/ntp/stop'

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
