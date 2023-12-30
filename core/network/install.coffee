
import quote from 'regexp-quote'

export default
  metadata:
    header: 'Network Install'
  handler: ({options}) ->
    # Hosts
    # Ovewrite the "/etc/hosts" file with the hostname resolution defined 
    # by the property "network.hosts". This configuration may be automatically
    # enriched with the cluster hostname if the property "network.hosts_auto" is
    # set.
    @file
      header: 'Hosts'
      if: Object.keys(options.hosts).length
      target: '/etc/hosts'
      replace: (
        "#{ip} #{hostnames}" for ip, hostnames of options.hosts
      ).join '\n'
      from: '# START RYBA'
      to: '# END RYBA'
      append: true
      backup: true
      eof: true
    write = []
    for ip in Object.keys options.host_replace
      write.push
        match: RegExp "^#{quote ip}\\s.*$", 'm'
        replace: "#{ip} #{options.host_replace[ip]}"
        append: true
    @file
      header: 'Host replace'
      if: write.length
      target: '/etc/hosts'
      write: write
      eof: true
    # Hostname
    # Declare the server hostname. According to `hostnamectl` documentation:
    # * "pretty": include all kinds of special characters (e.g. "Lennart's Laptop")
    # * "static": initialize the kernel hostname at boot (e.g. "lennarts-laptop")
    # * "transient": fallback value received from network configuration. 
    @call
      header: 'Hostname'
      unless: options.hostname_disabled
    , ->
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
          hostnamectl set-hostname #{options.hostname} --transient
          """
          code_skipped: 3
    # DNS resolv
    # Write the DNS configuration. On RH like system, this is configured
    # by the "/etc/resolv" file.
    # The [resolver](http://man7.org/linux/man-pages/man5/resolver.5.html) 
    # is a set of routines in the C library that provide
    # access to the Internet Domain Name System (DNS). The
    # configuration file is considered a trusted source of DNS information.
    @call
      header: 'Manual DNS Resolver'
      if: -> options.resolv
    , ->
      @file
        if: options.resolv
        content:  options.resolv
        target: '/etc/resolv.conf'
        backup: true
        eof: true
      @service.stop
        header: "Deactivate systemd-resolved"
        name: "systemd-resolved"
      @service.startup
        header: "Disable systemd-resolved"
        name: "systemd-resolved"
        startup: false
      @connection.wait
        servers: options.dns
    # Systemd DNS resolv
    # If systemd_resolv is set, the [systemd resolver](http://man7.org/linux/man-pages/man8/systemd-resolved.service.8.html) is activated
    # The resolver file (/etc/resolv.conf) is linked to `/run/systemd/resolve/stub-resolv.conf`
    # or to the backup `/run/systemd/resolve/resolv.conf` if the first does not exist.
    # In systemd version prior to 228, the `/run/systemd/resolve/stub-resolv.conf` file does
    # not exist and systemd-resolved does not accept Domain search, Stub DNS and a lot of other options.
    # It is recommended to symlink `/etc/resolv.conf` to a systemd-resolved managed file cited above.
    @call
      header: 'Systemd DNS resolver'
      if: -> options.systemd_resolv
    , ->
      @service
        header: "Install systemd-resolved"
        unless_os: name: ["ubuntu"]
        name: 'systemd-resolved'
        startup: true
        state: "started"
      @file
        header: "systemd-resolved config"
        if: options.systemd_resolv
        content: options.systemd_resolv
        target: '/etc/systemd/resolved.conf'
        backup: true
        eof: true
      @service.restart
        header: "Restart systemd-resolved"
        name: 'systemd-resolved'
      @system.execute
        cmd: """
        ls /run/systemd/resolve/stub-resolv.conf || exit 42
        """
        code_skipped: 42
      , (err, {code}) ->
        resolv_link = if code is 42 then "/run/systemd/resolve/resolv.conf" else "/run/systemd/resolve/stub-resolv.conf"
        @system.execute
          header: "Link resolv.conf"
          cmd: """
          link="#{resolv_link}"
          ls -l /etc/resolv.conf | grep $link && exit 42
          rm -f /etc/resolv.conf
          ln -s $link /etc/resolv.conf
          """
          code_skipped: 42
      @connection.wait
        servers: options.dns
    # Interfaces
    # Customize the network interfaces configured present inside the
    # "/etc/sysconfig/network-scripts" folder.
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
