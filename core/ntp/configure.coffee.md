
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
      options = @config.ntp ?= {}
      options.servers ?= []
      options.servers = options.servers.split(',') if typeof options.servers is 'string'
      options.lag ?= 2000
      options.fudge ?= false
      options.fudge = if @config.host in options.servers then 10 else 14
