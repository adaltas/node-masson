
# Iptables

Administration tool for IPv4 packet filtering and NAT.

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

    export default
      deps:
        yum: module: 'masson/core/yum', local: true
      configure:
        'masson/core/iptables/configure'
      commands:
        'install':
          'masson/core/iptables/install'
        'start':
          'masson/core/iptables/start'
        'stop':
          'masson/core/iptables/stop'
