
# Network

Modify the various network related configuration files such as
"/etc/hosts" and "/etc/resolv.conf".

    exports = module.exports = []
    exports.push 'masson/bootstrap'

# Configuration

The module accept the following properties:

*   `hostname` (boolean)   
    The server hostname as return by the command "hostname" and defined by the 
    property "HOSTNAME" inside the "/etc/sysconfig/network" file, must not be 
    configure globally, default to the "host" property.   
*   `network.hostname_disabled` (boolean)   
    Do not update the "/etc/sysconfig/network" file, disable the effect of the
    "hostname" property (which itself default to "host"), 
    default to false.   
*   `network.hosts_auto` (boolean)   
    Enrich the "/etc/hosts" file with the server hostname present on 
    the cluster, default to false   
*   `network.hosts` (object)   
    Enrich the "/etc/hosts" file with custom adresses, the keys represent the 
    IPs and the value the hostnames, optional.   
*   `network.resolv` (string)   
    Content of the '/etc/resolv.conf' file, optional.   

Example:

```json
{
  "network": {
    "hosts_auto": true,
    "hosts": {
      "10.10.10.15": "myserver.hadoop"
    },
    "resolv": "search hadoop\nnameserver 10.10.10.16\nnameserver 10.0.2.3"
    "ifcfg": {
      "eth0": {
        "PEERDNS": "no"
      }
    }
  }
}
```

    exports.configure = (ctx) ->
      ctx.config.hostname ?= ctx.config.host
      ctx.config.network ?= {}
      ctx.config.network.hostname_disabled ?= false
      ctx.config.network.hosts_auto ?= false
      ctx.config.shortname ?= ctx.config.host.split('.')[0]
      for host, server of ctx.config.servers
        server.shortname ?= server.host.split('.')[0]

## Network # Hosts

Ovewrite the "/etc/hosts" file with the hostname resolution defined 
by the property "network.hosts". This configuration may be automatically
enriched with the cluster hostname if the property "network.hosts_auto" is
set. Set the "network.hosts_disabled" to "true" if you dont wish to overwrite
this file.

    exports.push name: 'Network # Hosts', handler: ->
      {hosts, hosts_auto} = @config.network
      write = []
      if hosts_auto then for _, server of @config.servers
        write.push 
          match: RegExp "^#{quote server.ip}\\s.*$", 'gm'
          replace: "#{server.ip} #{server.host} #{server.shortname}"
          append: true
      for ip, hostnames of hosts
        write.push 
          match: RegExp "^#{quote ip}\\s.*$", 'gm'
          replace: "#{ip} #{hostnames}"
          append: true
      @write
        destination: '/etc/hosts'
        write: write
        backup: true
        eof: true

## Network # Hostname

Declare the server hostname. On CentOs like system, the 
relevant file is "/etc/sysconfig/network".

    exports.push
      name: 'Network # Hostname'
      not_if: -> @config.network.hostname_disabled
      handler: ->
        {hostname, network} = @config
        restart = false
        @write
          match: /^HOSTNAME=.*/mg
          replace: "HOSTNAME=#{hostname}"
          destination: '/etc/sysconfig/network'
        , (err, replaced) ->
          restart = true if replaced
        @execute
          cmd: "hostname #{@config.host} && service network restart"
          if: -> restart

## Network # DNS resolv

Write the DNS configuration. On CentOs like system, this is configured 
by the "/etc/resolv" file.

The [resolver](http://man7.org/linux/man-pages/man5/resolver.5.html) 
is a set of routines in the C library that provide
access to the Internet Domain Name System (DNS). The
configuration file is considered a trusted source of DNS information.

    exports.push
      name: 'Network # DNS Resolver'
      timeout: -1
      if: -> @config.network.resolv
      handler: ->
        @write
          content:  @config.network.resolv
          destination: '/etc/resolv.conf'
          backup: true
          eof: true
        @wait_connect
          servers: for bs_ctx in @contexts 'masson/core/bind_server'
            continue if bs_ctx is @
            host: bs_ctx.config.ip or bs_ctx.config.host
            port: 53

## Interfaces

Customize the network interfaces configured present inside the
"/etc/sysconfig/network-scripts" folder.

    exports.push
      name: 'Network # Interfaces'
      timeout: -1
      if: -> @config.network.ifcg
      handler: ->
        for name, config of @config.network
          @write
            destination: "/etc/sysconfig/network-scripts/ifcfg-#{name}"
            write: for k, v of config
              match: ///^#{quote k}=.*$///mg
              replace: "#{k}=#{v}"
              append: true
            backup: false
            eof: true

## Dependencies

    quote = require 'regexp-quote'
