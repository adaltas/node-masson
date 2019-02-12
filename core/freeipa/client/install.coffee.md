
# FreeIPA Server Install

Install the FreeIPA Server

    module.exports = header: 'FreeIPA Client Install', handler: ({options}) ->

## Package

      @service
        header: 'Package'
        name: 'ipa-client'

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
        header: 'TLS'
        unless_exec: [
          'ipa-getcert', 'list'
          "-f #{options.tls.cert}"
        ].join ' '
        cmd: [
          'ipa-getcert', 'request', '-r'
          "-k #{options.tls.key}"
          "-f #{options.tls.cert}"
          "-D #{options.fqdn}"
          "-K #{options.tls.principal}"
        ].join ' '

## Notes

Renewable tickets is per default disallowed in the most linux distributions. This can be done per:

```bash
kadmin.local: modprinc -maxrenewlife 7day krbtgt/YOUR_REALM
kadmin.local: modprinc -maxrenewlife 7day +allow_renewable hue/FQRN
```
