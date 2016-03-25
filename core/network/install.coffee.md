
# Network 

    module.exports = header: 'Network Install', handler: ->

## Hosts

Ovewrite the "/etc/hosts" file with the hostname resolution defined 
by the property "network.hosts". This configuration may be automatically
enriched with the cluster hostname if the property "network.hosts_auto" is
set. Set the "network.hosts_disabled" to "true" if you dont wish to overwrite
this file.

      {hosts, hosts_auto} = @config.network
      write = []
      if hosts_auto then for ctx in @contexts()
        write.push 
          match: RegExp "^#{quote ctx.config.ip}\\s.*$", 'gm'
          replace: "#{ctx.config.ip} #{ctx.config.host} #{ctx.config.shortname}"
          append: true
      for ip, hostnames of hosts
        write.push 
          match: RegExp "^#{quote ip}\\s.*$", 'gm'
          replace: "#{ip} #{hostnames}"
          append: true
      @write
        header: 'Network # Hosts'
        destination: '/etc/hosts'
        write: write
        backup: true
        eof: true

## Hostname

Declare the server hostname. On CentOs like system, the 
relevant file is "/etc/sysconfig/network".

      @call
        header: 'Network # Hostname'
        unless: -> @config.network.hostname_disabled
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

      @call
        header: 'Network # DNS Resolver'
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

      @write (
        header: 'Network # Interfaces'
        timeout: -1
        if: -> @config.network.ifcg
        destination: "/etc/sysconfig/network-scripts/ifcfg-#{name}"
        write: for k, v of config
          match: ///^#{quote k}=.*$///mg
          replace: "#{k}=#{v}"
          append: true
        backup: false
        eof: true
      ) for name, config of @config.network

## Dependencies

    quote = require 'regexp-quote'
