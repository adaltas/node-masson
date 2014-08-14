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
*   `iptables.action` (string)
    Action to apply to the service, possible vales are "start" and "stop",
    default to "start".
*   `iptables.rules` (array)
    A list of rules to be added to iptables.

Example:
```json
{
  "iptables": {
    "startup": "2,3,4,5",
    "action": "stop",
    "rules": [
      { "chain": "INPUT", "jump": "ACCEPT", "source": "10.10.10.0/24", "comment": "Local" }
    ]
  }
}
```

    module.exports.push module.exports.configure = (ctx) ->
      iptables = ctx.config.iptables ?= {}
      iptables.action ?= 'start'
      # Service supports chkconfig, but is not referenced in any runlevel
      iptables.startup ?= ''
      iptables.rules ?= []
      iptables.log ?= true
      iptables.log_prefix ?= 'IPTables-Dropped: '
      iptables.log_level ?= 4
      iptables.log_rules ?= [
        { chain: 'INPUT', command: '-A', jump: 'LOGGING' }
        { chain: 'LOGGING', command: '-A', '--limit': '2/min', jump: 'LOG', 'log-prefix': iptables.log_prefix, 'log-level': iptables.log_level }
        { chain: 'LOGGING', command: '-A', jump: 'DROP' }
      ]

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

## Log

Redirect input logs in "/var/log/messages".

    module.exports.push name: 'Iptables # Log', timeout: -1, callback: (ctx, next) ->
      {action, log, log_rules} = ctx.config.iptables
      return next() unless action is 'start'
      ctx.iptables
        rules: log_rules
        # if: action is 'start'
      , (err, configured) ->
        return next err, ctx.PASS if err or not configured
        ctx.service
          srv_name: 'restart'
        , (err) ->
        next err, ctx.OK

## Rules

Add user defined rules to IPTables.

    module.exports.push name: 'Iptables # Rules', timeout: -1, callback: (ctx, next) ->
      {rules, action} = ctx.config.iptables
      return next() unless action is 'start'
      return next null, ctx.PASS unless rules.length
      ctx.iptables
        rules: rules
        # if: action is 'start'
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

