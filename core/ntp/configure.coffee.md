
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

    export default (service) ->
      options = service.options
      
      options.fqdn ?= service.node.fqdn
      options.servers ?= []
      options.servers = options.servers.split(',') if typeof options.servers is 'string'
      options.lag ?= 2000
      options.fudge ?= false
      options.fudge = if options.fqdn in options.servers then 10 else 14
