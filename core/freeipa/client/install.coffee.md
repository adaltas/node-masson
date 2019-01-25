
# FreeIPA Server Install

Install the FreeIPA Server

    module.exports = header: 'FreeIPA Client Install', handler: ({options}) ->


## Package

      @service
        name: 'ipa-client'

## Setup

      #wait
      @call header: 'Register', handler: ->
        cmd = 'ipa-client-install -U --force-join '
        cmd += "--server #{options.ipa_host} "
        if options.dns_enabled
          cmd += "--enable-dns-updates "
          cmd += "--domain #{options.dns_domain_name} "
        cmd += "--realm=#{options.krb5_realm_name} -w #{options.admin_password} -p admin "
        cmd += "--hostname=#{options.fqdn}"
        @system.execute
          header: 'setup client'
          cmd: cmd
          unless_exec: "echo #{options.admin_password} | kinit -p admin"

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
