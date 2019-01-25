
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
        @system.group options[usr].group
        @system.user options[usr].user

## Package

      @service
        name: 'freeipa-server'
      @service
        if: options.dns_enabled
        name: 'ipa-server-dns'

## Layout

      @system.mkdir
        target: options.conf_dir

## TLS

      (if options.tls_ca_cert_local then @file.download else @system.copy)
        header: 'Deploy Cert'
        source: options.tls_cert_file
        target: "#{options.conf_dir}/cacert.pem"
        # uid: 'ldap'
        # gid: 'ldap'
        mode: 0o0400
      (if options.tls_key_local then @file.download else @system.copy)
        header: 'Deploy Key'
        source: options.tls_key_file
        target: "#{options.conf_dir}/key.pem"
        # uid: 'ldap'
        # gid: 'ldap'
        mode: 0o0400


## Setup

      @call header: 'Setup', handler: ->
        cmd = 'ipa-server-install -U '
        cmd += "--hostname=#{options.fqdn} "
        #krb5 mit realm
        cmd += "-r #{options.realm_name} -a #{options.admin_password} -p #{options.manager_password} "
        #dns options
        if options.dns_enabled
          cmd += '--setup-dns '
          cmd += "#{options.dns_host} "
          cmd += "-n #{options.dns_domain_name} "
          cmd += "--auto-reverse " if options.dns_auto_reverse
          cmd += '--auto-forwarders ' if options.dns_autoforward
          cmd += if options.dns_forwarder? then "--forwarder=#{options.dns_forwarder}" else '--no-forwarders'
        if !options.ntp_enabled
          cmd += '--no-ntp '
        if options.tls_enabled
          cmd += " --ca-cert-file=#{options.conf_dir}/cacert.pem"
        @system.execute
          header: 'setup ipa server'
          cmd: cmd
          # unless_exec: "#{cmd} | grep 'IPA server is already configured on this system'"
        
## Dependencies

    fs = require 'ssh2-fs'
    path = require('path').posix
    each = require 'each'
    misc = require 'nikita/lib/misc'

## Notes

Renewable tickets is per default disallowed in the most linux distributions. This can be done per:

```bash
kadmin.local: modprinc -maxrenewlife 7day krbtgt/YOUR_REALM
kadmin.local: modprinc -maxrenewlife 7day +allow_renewable hue/FQRN
```
