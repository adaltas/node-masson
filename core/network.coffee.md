
# Network

Modify the various network related configuration files such as
"/etc/hosts" and "/etc/resolv.conf".

    quote = require 'regexp-quote'
    module.exports = []
    module.exports.push 'masson/bootstrap'

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
  "hosts_auto": true,
  "hosts": {
    "10.10.10.15": "myserver.hadoop"
  },
  "resolv": "search hadoop\nnameserver 10.10.10.16\nnameserver 10.0.2.3"
}
```

    module.exports.push (ctx) ->
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

    module.exports.push name: 'Network # Hosts', callback: (ctx, next) ->
      {hosts, hosts_auto} = ctx.config.network
      # content = ''
      write = []
      if hosts_auto then for server in ctx.config.servers
        # content += "#{server.ip} #{server.host}\n"
        write.push 
          match: RegExp "^#{quote server.ip}\\s.*$", 'gm'
          replace: "#{server.ip} #{server.host} #{server.shortname}"
          append: true
      for ip, hostnames of hosts
        # content += "#{ip} #{hostnames}\n"
        write.push 
          match: RegExp "^#{quote ip}\\s.*$", 'gm'
          replace: "#{ip} #{hostnames}"
          append: true
      return next() unless write.length
      ctx.write
        destination: '/etc/hosts'
        write: write
        backup: true
        eof: true
      , next

## Network # Hostname

Declare the server hostname. On CentOs like system, the 
relevant file is "/etc/sysconfig/network".

    module.exports.push name: 'Network # Hostname', callback: (ctx, next) ->
      {hostname, network} = ctx.config
      return next() if network.hostname_disabled
      ctx.write
        match: /^HOSTNAME=.*/mg
        replace: "HOSTNAME=#{hostname}"
        destination: '/etc/sysconfig/network'
      , (err, replaced) ->
        return next err, false if err or not replaced 
        ctx.execute
          cmd: "hostname #{ctx.config.host} && service network restart"
        , next()

## Network # DNS resolv

Write the DNS configuration. On CentOs like system, this is configured 
by the "/etc/resolv" file.

The [resolver](http://man7.org/linux/man-pages/man5/resolver.5.html) 
is a set of routines in the C library that provide
access to the Internet Domain Name System (DNS). The
configuration file is considered a trusted source of DNS information.

    module.exports.push name: 'Network # DNS Resolver', timeout: -1, callback: (ctx, next) ->
      {resolv} = ctx.config.network
      return next() unless resolv
      # nameservers = []
      # re = /nameserver(.*)/g
      # while (match = re.exec resolv) isnt null
      #   nameservers.push match[1].trim()
      ctx.write
        content: resolv
        destination: '/etc/resolv.conf'
        backup: true
      , (err, written) ->
        return next err if err
        bind_server_hosts = ctx.hosts_with_module 'masson/core/bind_server'
        bind_server_hosts = for host in bind_server_hosts
          continue if host is ctx.config.host
          ctx.hosts[host].config.ip or host
        ctx.waitIsOpen bind_server_hosts, 53, (err) ->
          next err, written


