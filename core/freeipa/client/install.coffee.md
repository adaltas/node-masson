
# FreeIPA Server Install

Install the FreeIPA Server

    module.exports = header: 'FreeIPA Client Install', handler: ({options}) ->

## Package

      @service header: 'Package', [
        if_os: name: ['redhat','centos']
        name: 'ipa-client'
      ,
        if_os: name: ['ubuntu']
        name: 'freeipa-client'
      ]

## Setup

      @connection.wait
        header: 'Wait'
        host: options.ipa_fqdn
        port: 443
        
      @system.execute
        header: 'Setup'
        unless_exists: '/etc/ipa/default.conf'
        cmd: [
          'ipa-client-install', '-U' # --force-join
          "--server #{options.ipa_fqdn}" # Dont use IP or setup will crash
          "--realm #{options.realm_name}", "-w #{options.admin_password}", "-p admin "
          "--hostname=#{options.fqdn}"
          "--domain #{options.domain}"
          "--enable-dns-updates" if options.dns_enabled
        ].join ' '
      
      @system.execute
        header: 'SSL'
        unless_exec: [
          'ipa-getcert', 'list'
          "-f #{options.ssl.cert}"
        ].join ' '
        cmd: [
          'ipa-getcert', 'request', '-r'
          "-k #{options.ssl.key}"
          "-f #{options.ssl.cert}"
          "-D #{options.fqdn}"
          "-K #{options.ssl.principal}"
        ].join ' '

## Configure

Modify the Kerberos configuration file in "/etc/krb5.conf". Note, 
this action wont be run if the server host a Kerberos server. 
This is to avoid any conflict where both modules would try to write 
their own configuration one. We give the priority to the server module 
which create a Kerberos file with complementary information.

      @file.types.krb5_conf
        header: 'KRB5 Configuration'
        if: options.krb5_conf.enabled
      , options.krb5_conf

## Notes

Renewable tickets is per default disallowed in the most linux distributions. This can be done per:

```bash
kadmin.local: modprinc -maxrenewlife 7day krbtgt/YOUR_REALM
kadmin.local: modprinc -maxrenewlife 7day +allow_renewable hue/FQRN
```
