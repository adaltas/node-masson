
# FreeIPA Server Install

Install the FreeIPA Server

    module.exports = header: 'FreeIPA Server Install', handler: ({options}) ->
    
## IPTables

| Service    | Port | Proto | Parameter                            |
|------------|------|-------|--------------------------------------|
| kadmin     | 749  | tcp   | `kdc_conf.kdcdefaults.kadmind_port`  |
| krb5kdc    | 88   | upd   | `kdc_conf.kdcdefaults.kdc_ports`     |
| krb5kdc    | 88   | tcp   | `kdc_conf.kdcdefaults.kdc_tcp_ports` |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rules = []
      # rules.push chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'udp', state: 'NEW', comment: "Kerberos Authentication Service and Key Distribution Center (krb5kdc daemon)"
      rules.push chain: 'INPUT', jump: 'ACCEPT', dport: 389 , protocol: 'tcp', state: 'NEW', comment: "LDAP"
      rules.push chain: 'INPUT', jump: 'ACCEPT', dport: 636, protocol: 'tcp', state: 'NEW', comment: "LDAP SSL"
      rules.push chain: 'INPUT', jump: 'ACCEPT', dport: 88 , protocol: 'tcp', state: 'NEW', comment: "Kerberos krb5kdc TCP"
      rules.push chain: 'INPUT', jump: 'ACCEPT', dport: 464, protocol: 'tcp', state: 'NEW', comment: "Kerberos kadmin TCP"
      rules.push chain: 'INPUT', jump: 'ACCEPT', dport: 88 , protocol: 'udp', state: 'NEW', comment: "Kerberos krb5kdc UDP"
      rules.push chain: 'INPUT', jump: 'ACCEPT', dport: 464, protocol: 'udp', state: 'NEW', comment: "Kerberos kadmin UDP"
      rules.push chain: 'INPUT', jump: 'ACCEPT', dport: 80, protocol: 'tcp', state: 'NEW', comment: "FreeIPA WebUI"
      rules.push chain: 'INPUT', jump: 'ACCEPT', dport: 443, protocol: 'tcp', state: 'NEW', comment: "FreeIPA WebUI SSL"
      rules.push chain: 'INPUT', jump: 'ACCEPT', dport: 53, protocol: 'tcp', state: 'NEW', comment: "Bind Server TCP" if options.dns_enabled
      rules.push chain: 'INPUT', jump: 'ACCEPT', dport: 53, protocol: 'udp', state: 'NEW', comment: "Bind Server UDP" if options.dns_enabled
      rules.push chain: 'INPUT', jump: 'ACCEPT', dport: 123, protocol: 'udp', state: 'NEW', comment: "NTP UDP" if options.ntp
      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: rules

## Identities

      for usr in ['hsqldb', 'apache', 'memcached', 'ods', 'tomcat', 'pkiuser', 'dirsrv']
        @system.group
          header: "Group #{usr}"
          if: options.manage_users_groups
        , options[usr].group
        @system.user
          header: "User #{usr}"
          if: options.manage_users_groups
        , options[usr].user

## Package

      @call header: 'Packages', ->
        @service
          name: 'freeipa-server'
        @service
          if: options.dns_enabled
          name: 'ipa-server-dns'

## TLS

      (if options.tls_ca_cert_local then @file.download else @system.copy)
        header: 'Cert'
        if: options.tls_cert_file
        source: options.tls_cert_file
        target: "#{options.conf_dir}/cacert.pem"
        mode: 0o0400
      (if options.tls_key_local then @file.download else @system.copy)
        header: 'Key'
        if: options.tls_key_file
        source: options.tls_key_file
        target: "#{options.conf_dir}/key.pem"
        mode: 0o0400

      @system.execute
        header: 'Setup'
        unless_exists: '/etc/ipa/default.conf'
        cmd: [
          'ipa-server-install', '-U'
          #  Basic options
          "-a #{options.admin_password}"
          "-p #{options.manager_password}"
          "--hostname #{options.hostname}"
          "--domain #{options.domain}" # Same as -n
          "--ip-address #{options.ip_address}"
          # Server options
          "--idstart=#{options.idstart}" if options.idstart
          "--idmax=#{options.idmax}" if options.idmax
          # Kerberos REALM
          "-r #{options.realm_name}"
          # DNS
          ...[
            '--setup-dns'
            '--auto-reverse' if options.dns_auto_reverse
            '--auto-forwarders' if typeof options.dns_auto_forward is 'boolean'
            ...( for forwarder in options.dns_forwarder
              "--forwarder=#{forwarder}"
            ) if Array.isArray options.dns_forwarder
          ] if options.dns_enabled
          '--no-ntp' unless options.ntp_enabled
          ...[
            if options.external_ca
              "--external-ca --ca-subject=\"#{options.ca_subject}\""
            else
              "--ca-cert-file=#{options.conf_dir}/cacert.pem"
          ] if options.tls_enabled
        ].join ' '
        bash: 'bash -l'
      
      @call
        if_exists: '/root/ipa.csr'
        unless_exists: '/root/ipa.cert'
        header: 'External CA'
      , (err, callback) ->
        @call ->
          process.stdout.write [
            'The next step is to get /root/ipa.csr signed by your CA'
            'and place the certificate chain, the root and the intermediate'
            'certificates, in /root/ipa.cert in the PEM format', ''
          ].join '\n' if process.stdin.isTTY
        @wait.exist
          target: '/root/ipa.cert'
        @call ->
          process.stdout.write [
            'Be sure to back up the CA certificates stored in /root/cacert.p12'
            'These files are required to create replicas. The password for these'
            'files is the Directory Manager password', ''
          ].join '\n' if process.stdin.isTTY
        @next callback
      @call
        header: 'Certificate'
        if: -> @status -1
      , ->
        @system.execute
          unless_exists: '/var/lib/ipa-client/sysrestore/sysrestore.index'
          cmd: [
            'ipa-server-install'
            "-p #{options.manager_password}"
            '--external-cert-file=/root/ipa.cert'
          ].join ' '
        @system.execute
          if_exists: '/var/lib/ipa-client/sysrestore/sysrestore.index'
          cmd: [
            'ipa-cacert-manage', 'renew'
            "-p #{options.manager_password}"
            '--external-cert-file=/root/ipa.cert'
          ].join ' '
        @fs.unlink
          header: 'Cleanup'
        , [
          '/root/ipa.cert'
          '/root/ipa.csr'
        ]
        
      @call
        header: 'DNS'
        if: options.dns_enabled
        unless: -> @status -3
      , ({}, callback) ->
        @system.execute
          cmd: """
          echo #{options.admin_password} | kinit admin
          ipa dnsserver-find
          """
        , (err, {stdout}) ->
          return callback err if err
          forwarders = parse_dnsserver_find_forwarders stdout, options.fqdn
          @system.execute
            cmd: [
              'ipa-dns-install', '-U'
              '--auto-reverse' if options.dns_auto_reverse
              '--auto-forwarders' if options.dns_auto_forward
              ...( for forwarder in options.dns_forwarder
                "--forwarder=#{forwarder}"
              )
            ].join ' '
          , (err, {status}) ->
            callback err, status

## Utils

    parse_dnsserver_find_forwarders = (data, fqdn) ->
      servers = {}
      server = null
      for line in data.split '\n'
        if match = /^\s+Server name:\s+(.*)$/.exec line
          server = match[1]
          servers[server] = []
        if match = /^\s+Forwarders:\s+(.*)$/.exec line
          forwarders = match[1].split(',').map (forwarder) -> forwarder.trim()
          servers[server] = forwarders
      if fqdn
        servers[fqdn]
      else
        servers

## Notes

Renewable tickets is per default disallowed in the most linux distributions. This can be done per:

```bash
kadmin.local: modprinc -maxrenewlife 7day krbtgt/YOUR_REALM
kadmin.local: modprinc -maxrenewlife 7day +allow_renewable hue/FQRN
```
