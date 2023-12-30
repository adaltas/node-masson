
# FreeIPA Server Install

Install the FreeIPA Server

schema =
  type: 'object'
  properties:
    'admin_password':
      type: 'string'
      description: """
      """
    'apache':
      type: 'object'
      description: """
      Information relative to the apache user.
      """
      properties:
        group: '$ref': 'registry://system/group'
        user: '$ref': 'registry://system/user'
    'ca_subject':
      type: ''
      description: """
      The certificate authority (CA) subject, it corresponds to the
      "--ca-subject" IPA argument and it is only used if 'external_ca' is
      `true`. An exemple is `"CN=Certificate Authority,O=AU.ADALTAS.CLOUD"`.
      """
    'conf_dir':
      type: ''
      description: """
      """
    'dirsrv':
      type: 'object'
      description: """
      Information relative to the dirsrv user.
      """
      properties:
        group: '$ref': 'registry://system/group'
        user: '$ref': 'registry://system/user'
    'dns_auto_forward':
      type: ''
      description: """
      """
    'dns_auto_reverse':
      type: ''
      description: """
      """
    'dns_enabled':
      type: 'boolean'
      description: """
      """
    'dns_forwarder':
      type: 'array'
      description: """
      The DNS forwarder used to forward external DNS requests. It
      corresponds to the "--forwarder" IPA argument. An example is
      `[['1.1.1.1', '1.0.0.1']]`.
      """
      items:
        type: 'string'
        format: 'ipv4'
    'domain':
      type: ''
      description: """
      """
    'external_ca':
      type: 'boolean'
      description: """
      Indicate the usage of an external certificate authority (CA).
      """
    'fqdn':
      type: ''
      description: """
      The server FQDN. It corresponds to the "--hostname" IPA argument.
      """
    'hsqldb':
      type: 'object'
      description: """
      Information relative to the hsqldb user.
      """
      properties:
        group: '$ref': 'registry://system/group'
        user: '$ref': 'registry://system/user'
    'idmax':
      type: ''
      description: """
      """
    'idstart':
      type: ''
      description: """
      """
    'ip_address':
      type: ''
      description: """
      """
    'iptables':
      type: ''
      description: """
      """
    'manage_users_groups':
      type: ''
      description: """
      """
    'manager_password':
      type: ''
      description: """
      """
    'memcached':
      type: 'object'
      description: """
      Information relative to the memcached user.
      """
      properties:
        group: '$ref': 'registry://system/group'
        user: '$ref': 'registry://system/user'
    'no_krb5_offline_passwords':
      type: ''
      description: """
      """
    'ntp':
      type: 'boolean'
      description: """
      """
    'ntp_enabled':
      type: ''
      description: """
      """
    'ods':
      type: 'object'
      description: """
      Information relative to the ods user.
      """
      properties:
        group: '$ref': 'registry://system/group'
        user: '$ref': 'registry://system/user'
    'pkiuser':
      type: 'object'
      description: """
      Information relative to the pkiuser user.
      """
      properties:
        group: '$ref': 'registry://system/group'
        user: '$ref': 'registry://system/user'
    'realm_name':
      type: ''
      description: """
      """
    'ssl_ca_cert_local':
      type: ''
      description: """
      """
    'ssl_cert_file':
      type: ''
      description: """
      """
    'ssl_enabled':
      type: ''
      description: """
      """
    'ssl_key_local':
      type: ''
      description: """
      """
    'ssl_key_file':
      type: ''
      description: """
      """
    'tomcat':
      type: 'object'
      description: """
      Information relative to the tomcat user.
      """
      properties:
        group: '$ref': 'registry://system/group'
        user: '$ref': 'registry://system/user'

export default
  header: 'FreeIPA Server Install'
  handler: ({options}) ->
    # IPTables
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
      # Identities
      for usr in ['hsqldb', 'apache', 'memcached', 'ods', 'tomcat', 'pkiuser', 'dirsrv']
        @system.group
          header: "Group #{usr}"
          if: options.manage_users_groups
        , options[usr].group
        @system.user
          header: "User #{usr}"
          if: options.manage_users_groups
        , options[usr].user
      # Package
      @call header: 'Packages', ->
        @service
          name: 'freeipa-server'
        @service
          if: options.dns_enabled
          name: 'ipa-server-dns'
      # SSL/TLS
      (if options.ssl_ca_cert_local then @file.download else @system.copy)
        header: 'Cert'
        if: options.ssl_cert_file
        source: options.ssl_cert_file
        target: "#{options.conf_dir}/cacert.pem"
        mode: 0o0400
      (if options.ssl_key_local then @file.download else @system.copy)
        header: 'Key'
        if: options.ssl_key_file
        source: options.ssl_key_file
        target: "#{options.conf_dir}/key.pem"
        mode: 0o0400
      @system.execute
        header: 'Setup'
        unless_exists: '/etc/ipa/default.conf'
        unless_exec: 'echo > /dev/tcp/localhost/443'
        cmd: [
          'ipa-server-install', '-U'
          #  Basic options
          "-a #{options.admin_password}"
          "-p #{options.manager_password}"
          "--hostname #{options.fqdn}"
          "--domain #{options.domain}" # Same as -n
          "--ip-address #{options.ip_address}"
          # Server options
          "--idstart=#{options.idstart}" if options.idstart
          "--idmax=#{options.idmax}" if options.idmax
          # Kerberos REALM
          "-r #{options.realm_name}"
          "--no-krb5-offline-passwords" if options.no_krb5_offline_passwords
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
          ] if options.ssl_enabled
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

# Utils
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
