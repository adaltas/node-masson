
# Network Configure

## Options

The module accept the following properties:

*   `hostname` (boolean)   
    The server hostname as return by the command "hostname" and defined by the 
    property "HOSTNAME" inside the "/etc/sysconfig/network" file, must not be 
    configure globally, default to the "host" property.   
*   `network.hostname_disabled` (boolean)   
    Do not update the hostname, disable the effect of the
    "hostname" property (which itself default to "host"), 
    default to "false".   
*   `network.hosts_auto` (boolean)   
    Enrich the "/etc/hosts" file with the server hostname present on 
    the cluster, default to "false"   
*   `network.hosts` (object)   
    Enrich the "/etc/hosts" file with custom adresses, the keys represent the 
    IPs and the value the hostnames, optional.   
*   `network.resolv` (string)   
    Content of the '/etc/resolv.conf' file, optional.   
*   `network.host_replace` (string)   
    Custom hostname to replace in /etc/hosts, optional.   
*   `ifcg` (object)   
    Network interfaces configuration, keys are the interface name and filename 
    inside "/etc/sysconfig/network-scripts", value the configuration content.

## Default configuration

```json
{
  "hostname_disabled": false,
  "hosts_auto": false,
}
```

## Example

```json
{
    "hosts_auto": true,
    "hosts": {
      "10.10.10.15": "myserver.hadoop"
    },
    "resolv": "search hadoop\nnameserver 10.10.10.16\nnameserver 10.0.2.3"
    "ifcfg": {
      "eth0": {
        "PEERDNS": "no"
      }
    },
    "host_replace": {
      "10.10.10.11": "master1.new.ryba",
      "10.10.10.12": "master2.new.ryba",
      "10.10.10.13": "master3.new.ryba"
    }
}
```

    module.exports = ->
      @config.hostname ?= @config.host
      @config.shortname ?= @config.host.split('.')[0]
      service = migration.call @, service, 'masson/core/network', ['network'], require('nikita/lib/misc').merge require('.').use,
        bind_server: key: ['bind_server']
      options = @config.network = service.options
      
      options.ip = service.node.ip
      options.fqdn = service.node.fqdn
      options.hostname = service.node.hostname
      options.nodes = service.nodes
      
      options.hostname_disabled ?= false
      
## Hosts

      options.hosts_auto ?= false
      options.hosts ?= {}

## DNS Resolver

      options.dns = for bind in service.use.bind_server
        continue if bind.node.host is service.node.host
        host: bind.node.host
        port: bind.options.port

## Dependencies

    migration = require '../../lib/migration'
