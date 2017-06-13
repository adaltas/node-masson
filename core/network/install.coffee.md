
# Network Install

    module.exports = header: 'Network Install', handler: ->
      {network} = @config
      network_ctxs = @contexts 'masson/core/network'

## Hosts

Ovewrite the "/etc/hosts" file with the hostname resolution defined 
by the property "network.hosts". This configuration may be automatically
enriched with the cluster hostname if the property "network.hosts_auto" is
set. Set the "network.hosts_disabled" to "true" if you dont wish to overwrite
this file.

      content = []
      if network.hosts_auto then for ctx in network_ctxs
        content.push "#{ctx.config.ip} #{ctx.config.host} #{ctx.config.shortname}"
      for ip, hostnames of network.hosts
        content.push "#{ip} #{hostnames}"
      @file
        header: 'Hosts'
        if: content.length
        target: '/etc/hosts'
        replace: content.join '\n'
        from: '# START RYBA'
        to: '# END RYBA'
        append: true
        backup: true
        eof: true
      write = []
      if network.host_replace then for ip in Object.keys network.host_replace
        write.push
          match: RegExp "^#{quote ip}\\s.*$", 'm'
          replace: "#{ip} #{network.host_replace[ip]}"
      @file
        header: 'Host replace'
        if: network.host_replace?
        target: '/etc/hosts'
        write: write

## Hostname

Declare the server hostname. On RH6 based system, the 
relevant file is "/etc/sysconfig/network".

      @call
        header: 'Hostname'
        unless: -> @config.network.hostname_disabled
        handler: ->
          {hostname, shortname, network} = @config
          restart = false
          @call
            if_os: name: ['centos','redhat'], version: '6'
          , ->
            @file
              match: /^HOSTNAME=.*/mg
              replace: "HOSTNAME=#{shortname}"
              target: '/etc/sysconfig/network'
            , (err, replaced) ->
              restart = true if replaced
            @system.execute
              cmd: "hostname #{shortname} && service network restart"
              if: -> restart
          @call
            if_os: name: ['centos','redhat'], version: '7'
          , ->
            @system.execute
              header: 'FQDN'
              cmd: """
              fqdn=`hostnamectl status | grep 'Static hostname' | sed 's/^.* \\(.*\\)$/\\1/'`
              [[ $fqdn == "#{hostname}" ]] && exit 3
              hostnamectl set-hostname #{hostname} --static
              """
              code_skipped: 3
            # Note, transient hostname must be set after static
            # or only static will be set if static wasnt previously defined
            @system.execute
              header: 'Hostname'
              cmd: """
              fqdn=`hostnamectl status | grep 'Transient hostname' | sed 's/^.* \\(.*\\)$/\\1/'`
              [[ $fqdn == "#{shortname}" ]] && exit 3
              hostnamectl set-hostname #{shortname}
              """
              code_skipped: 3

## Network # DNS resolv

Write the DNS configuration. On RH like system, this is configured 
by the "/etc/resolv" file.

The [resolver](http://man7.org/linux/man-pages/man5/resolver.5.html) 
is a set of routines in the C library that provide
access to the Internet Domain Name System (DNS). The
configuration file is considered a trusted source of DNS information.

      @call
        header: 'DNS Resolver'
        if: -> @config.network.resolv
        handler: ->
          @file
            content:  @config.network.resolv
            target: '/etc/resolv.conf'
            backup: true
            eof: true
          @connection.wait
            servers: for bs_ctx in @contexts 'masson/core/bind_server'
              continue if bs_ctx is @
              host: bs_ctx.config.ip or bs_ctx.config.host
              port: 53

## Interfaces

Customize the network interfaces configured present inside the
"/etc/sysconfig/network-scripts" folder.

      @file (
        header: 'Interfaces'
        if: -> @config.network.ifcg
        target: "/etc/sysconfig/network-scripts/ifcfg-#{name}"
        write: for k, v of config
          match: ///^#{quote k}=.*$///mg
          replace: "#{k}=#{v}"
          append: true
        backup: false
        eof: true
      ) for name, config of @config.network

## Dependencies

    quote = require 'regexp-quote'
