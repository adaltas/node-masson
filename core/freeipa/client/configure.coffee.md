
## FreeIPA Client Configure

Follows [production deployment configuration](https://www.freeipa.org/page/Deployment_Recommendations)

    module.exports = (service) ->
      options = service.options
      options.fqdn = service.node.fqdn


## Modules

      # DNS
      if service.deps.ipa_server[0]?.length
        options.dns_enabled ?= service.deps.ipa_server[0]?.options.dns_enabled
        options.ipa_host ?= service.deps.ipa_server[0]?.node.fqdn
        options.dns_enabled ?= service.deps.ipa_server[0]?.options.dns_enabled
        options.ntp_enabled ?= service.deps.ipa_server[0]?.options.ntp_enabled
        options.krb5_realm_name ?= service.deps.ipa_server[0]?.options.krb5_realm_name
        options.admin_password ?= service.deps.ipa_server[0]?.options.admin_password
        if options.dns_enabled
          options.dns_domain_name ?= service.deps.ipa_server[0]?.options.dns_domain_name
          throw Error 'Required IPA Server Domain name' unless options.dns_domain_name?

## Client command

      options.admin ?= merge {} , service.deps.ipa_server[0]?.options.ntp_enabled, options.admin

## Wait

      options.wait = {}

## Dependencies

    {merge} = require '@nikitajs/core/lib/misc'
