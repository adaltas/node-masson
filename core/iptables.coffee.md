
# Iptables

Administration tool for IPv4 packet filtering and NAT.

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Configuration

Configuration is declared through the key "iptables" and may contains the following properties:   

*   `iptables.startup` (boolean|string)   
    Start the service on system startup, default to "2,3,4,5".   
*   `iptables.action` (string)   
    Action to apply to the service, possible vales are "start" and "stop",
    default to "start".   
*   `iptables.log` (boolean)   
    Enable log, default to "false".   
*   `iptables.log_prefix` (string)   
    String prefixing the log messages, default to "IPTables-Dropped: ".   
*   `iptables.log_level` (integer)   
    Log level, default ot "4".   
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

    exports.push module.exports.configure = (ctx) ->
      iptables = ctx.config.iptables ?= {}
      iptables.action ?= 'start'
      # Service supports chkconfig, but is not referenced in any runlevel
      iptables.startup ?= ''
      iptables.rules ?= []
      iptables.log ?= false
      iptables.log = iptables.log is 'true' if typeof iptables.log is 'string'
      iptables.log_prefix ?= 'IPTables-Dropped: '
      iptables.log_level ?= 4
      iptables.log_rules ?= [
        { chain: 'INPUT', command: '-A', jump: 'LOGGING' }
        { chain: 'LOGGING', command: '-A', '--limit': '2/min', jump: 'LOG', 'log-prefix': iptables.log_prefix, 'log-level': iptables.log_level }
        { chain: 'LOGGING', command: '-A', jump: 'DROP' }
      ]

## Package

The package "iptables" is installed.

    exports.push name: 'Iptables # Package', timeout: -1, handler: (ctx, next) ->
      {action, startup} = ctx.config.iptables
      ctx.service
        name: 'iptables'
        startup: startup
        action: action
      , next

## Log

Redirect input logs in "/var/log/messages".

    exports.push name: 'Iptables # Log', timeout: -1, handler: (ctx, next) ->
      {action, log, log_rules} = ctx.config.iptables
      return next() if action isnt 'start' or log is false
      ctx.iptables
        rules: log_rules
        # if: action is 'start'
      , (err, configured) ->
        return next err, false if err or not configured
        ctx.service
          srv_name: 'restart'
        , next

## Rules

Add user defined rules to IPTables.

    exports.push name: 'Iptables # Rules', timeout: -1, handler: (ctx, next) ->
      {rules, action} = ctx.config.iptables
      return next() unless action is 'start'
      return next null, ctx.PASS unless rules.length
      ctx.iptables
        rules: rules
        # if: action is 'start'
      , next

