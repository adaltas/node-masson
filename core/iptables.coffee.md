---
title: Iptables
module: masson/core/iptables
layout: module
---

# Iptables

Administration tool for IPv4 packet filtering and NAT.

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Configuration

Configuration is declared through the key "iptables" and may contains the following properties:   

*   `iptables.startup` (boolean|string)
    Start the service on system startup, default to "2,3,4,5".
*   `iptables.action`
    Action to apply to the service, default to "start".

Example:
```json
{
  "iptables": {
    "startup": "2,3,4,5",
    "action": "start"
  }
}
```

    module.exports.push (ctx) ->
      ctx.config.iptables ?= {}
      ctx.config.iptables.action ?= 'start'
      # Service supports chkconfig, but is not referenced in any runlevel
      ctx.config.iptables.startup ?= ''

## Package

The package "iptables" is installed.

    module.exports.push name: 'Iptables # Package', timeout: -1, callback: (ctx, next) ->
      {action, startup} = ctx.config.iptables
      ctx.service
        name: 'iptables'
        startup: startup
        action: action
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS
