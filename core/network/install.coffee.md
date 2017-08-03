
# Network Install

    module.exports = header: 'Network Install', handler: (options) ->

## Hosts

Ovewrite the "/etc/hosts" file with the hostname resolution defined 
by the property "network.hosts". This configuration may be automatically
enriched with the cluster hostname if the property "network.hosts_auto" is
set. Set the "network.hosts_disabled" to "true" if you dont wish to overwrite
this file.

      content = []
      if options.hosts_auto then for node in options.nodes
        content.push "#{node.ip} #{node.fqdn} #{node.hostname}"
      for ip, hostnames of options.hosts
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
      if options.host_replace then for ip in Object.keys options.host_replace
        write.push
          match: RegExp "^#{quote ip}\\s.*$", 'm'
          replace: "#{ip} #{options.host_replace[ip]}"
      @file
        header: 'Host replace'
        if: options.host_replace?
        target: '/etc/hosts'
        write: write

## Hostname

Declare the server hostname. On RH6 based system, the 
relevant file is "/etc/sysconfig/network".

      @call
        header: 'Hostname'
        unless: -> options.hostname_disabled
        handler: ->
          @call
            if_os: name: ['centos','redhat'], version: '6'
          , ->
            @file
              match: /^HOSTNAME=.*/mg
              replace: "HOSTNAME=#{options.hostname}"
              target: '/etc/sysconfig/network'
            @system.execute
              cmd: "hostname #{options.hostname} && service network restart"
              if: -> @status -1
          @call
            if_os: name: ['centos','redhat'], version: '7'
          , ->
            @system.execute
              header: 'FQDN'
              cmd: """
              fqdn=`hostnamectl status | grep 'Static hostname' | sed 's/^.* \\(.*\\)$/\\1/'`
              [[ $fqdn == "#{options.fqdn}" ]] && exit 3
              hostnamectl set-hostname #{options.fqdn} --static
              """
              code_skipped: 3
            # Note, transient hostname must be set after static
            # or only static will be set if static wasnt previously defined
            @system.execute
              header: 'Hostname'
              cmd: """
              hostname=`hostnamectl status | grep 'Transient hostname' | sed 's/^.* \\(.*\\)$/\\1/'`
              [[ $hostname == "#{options.hostname}" ]] && exit 3
              hostnamectl set-hostname #{options.hostname}
              """
              code_skipped: 3

## DNS resolv

Write the DNS configuration. On RH like system, this is configured 
by the "/etc/resolv" file.

The [resolver](http://man7.org/linux/man-pages/man5/resolver.5.html) 
is a set of routines in the C library that provide
access to the Internet Domain Name System (DNS). The
configuration file is considered a trusted source of DNS information.

      @call
        header: 'DNS Resolver'
        if: -> options.resolv
        handler: ->
          @file
            content:  options.resolv
            target: '/etc/resolv.conf'
            backup: true
            eof: true
          @connection.wait
            servers: options.dns

## Interfaces

Customize the network interfaces configured present inside the
"/etc/sysconfig/network-scripts" folder.

      @file (
        header: 'Interfaces'
        if: -> options.ifcg
        target: "/etc/sysconfig/network-scripts/ifcfg-#{name}"
        write: for k, v of config
          match: ///^#{quote k}=.*$///mg
          replace: "#{k}=#{v}"
          append: true
        backup: false
        eof: true
      ) for name, config of options.ifcg

## Dependencies

    quote = require 'regexp-quote'
