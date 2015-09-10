
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

    module.exports.configure = (ctx) ->
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

    exports.push name: 'Iptables # Package', timeout: -1, handler: ->
      {action, startup} = @config.iptables
      @service
        name: 'iptables'
        startup: startup
        action: action

## Log

Redirect input logs in "/var/log/messages".

    exports.push
      name: 'Iptables # Log'
      timeout: -1
      not_if: -> @config.iptables.action isnt 'start' or @config.iptables.log is false
      handler: ->
        @iptables
          rules: @config.iptables.log_rules
        @service
          srv_name: 'restart'
          if: -> @status -1

## Rules

Add user defined rules to IPTables.

    exports.push
      name: 'Iptables # Rules'
      timeout: -1
      if: -> @config.iptables.action is 'start'
      handler: ->
        {rules, action} = @config.iptables
        return next() unless action is 'start'
        @iptables
          rules: rules
