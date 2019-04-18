
# Network Configure

## Options

The module accept the following properties:

*   `hostname` (boolean, optional)   
    The server hostname as return by the command "hostname" and defined by the 
    property "HOSTNAME" inside the "/etc/sysconfig/network" file, must not be 
    configure globally, default to the "host" property.
*   `hostname_disabled` (boolean, optional)   
    Do not update the hostname, disable the effect of the
    "hostname" property (which itself default to "host"), 
    default to "false".
*   `host_auto` (boolean, optional)   
    Enrich the "/etc/hosts" file with the server ip and hostname present on 
    the cluster, enriching the `host_replace`, default to "false".
*   `hosts_auto` (boolean, optional)   
    Enrich the "/etc/hosts" file with all the hostnames present in 
    the cluster, default to "false".
*   `hosts` (object, optional)   
    Enrich the "/etc/hosts" file with custom adresses, the keys represent the 
    IPs and the value the hostnames.
*   `resolv` (string, optional)   
    Content of the '/etc/resolv.conf' file.
    'systemd-resolved' will be deactivated if set
*   `systemd_resolv` (string, optional)
    Content of '/etc/systemd/resolved.conf'.
    'systemd-resolved' will be activated  if this is set.
    Both `resolv` and `systemd_resolv` can't be set at the same time.
*   `host_replace` (string, optional)   
    Custom hostname to replace in /etc/hosts.
*   `ifcg` (object, optional)   
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

    module.exports = ({deps, options, node, instances}) ->

      options.ip = node.ip
      options.fqdn = node.fqdn
      options.hostname = node.hostname
      throw Error 'Both resolv and systemd_resolv cannot be set at the same time' if options.resolv and options.systemd_resolv

## Hosts

      options.hosts_auto ?= false
      options.own_host ?= false # For when fqdn of the current host is already in /etc/hosts, we will want to avoid duplication
      options.hosts ?= {}
      options.host_replace ?= {}
      options.hostname_disabled ?= true
      if options.hosts_auto then for instance in instances
        throw Error "Required Property: node must define an IP" unless instance.node.ip
        options.hosts[instance.node.ip] = "#{instance.node.fqdn} #{instance.node.hostname}" unless instance.node.ip is options.ip and options.own_host
      options.host_auto ?= false
      if options.host_auto
        throw Error "Required Property: node must define an IP" unless node.ip
        options.host_replace[node.ip] = "#{node.fqdn} #{node.hostname}"

## DNS Resolver

      if deps.bind_server
        options.dns = for bind in deps.bind_server
          continue if bind.node.host is node.host
          host: bind.node.host
          port: bind.options.port
