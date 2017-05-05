
# NTP Configure

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
    "lag": 2000,
    "fudge": false
  }
}
```

    module.exports = ->
      ntp = @config.ntp ?= {}
      ntp.servers ?= []
      ntp.servers = @config.ntp.servers.split(',') if typeof @config.ntp.servers is 'string'
      ntp.lag ?= 2000
      ntp.fudge ?= false
      ntp.fudge = if @config.host in ntp.servers then 10 else 14
