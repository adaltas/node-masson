
# FreeIPA Client Configure

Follows [production deployment configuration](https://www.freeipa.org/page/Deployment_Recommendations)

Options:

* `tls.cert` (string, optional, "/etc/ipa/cert.pem")   
  Path where to store the certificate.
* `tls.enabled` (boolean, optional, false)   
  Enable certificate generation and tracking.
* `tls.key` (string, optional, "/etc/ipa/key.pem")   
  Path where to store the private key.
* `tls.subject` (string|object, optional, "CN=<fqdn>")   
  Requested subject name.
* `tls.subject.CN` (string, optional, "<fqdn>")   
  Common name.
* `tls.subject.O` (string, optional)   
  Organisation name.
* `tls.principal` (string, optional, "HTTP/<fqdn>")   
  Requested principal name.

## Example setting a custom organization name

```json
{ "tls":
  "enabled": true
  "subject": {
    "O": "AU.ADALTAS.CLOUD"
} }
```

## Source code

    module.exports = ({options, node, deps}) ->
      options.fqdn = node.fqdn
      ipa_server = if deps.ipa_server?.length then deps.ipa_server[0] else null

## Modules

      if ipa_server
        options.dns_enabled ?= ipa_server.options.dns_enabled
        options.ipa_fqdn ?= ipa_server.node.fqdn
        options.dns_enabled ?= ipa_server.options.dns_enabled
        options.ntp_enabled ?= ipa_server.options.ntp_enabled
        options.realm_name ?= ipa_server.options.realm_name
        options.admin_password ?= ipa_server.options.admin_password
        if options.dns_enabled
          options.domain ?= ipa_server.options.domain
          throw Error 'Required IPA Server Domain name' unless options.domain?

## TLS

      options.tls ?= {}
      if options.tls.enabled
        options.tls.cert ?= '/etc/ipa/cert.pem'
        options.tls.key ?= '/etc/ipa/key.pem'
        options.tls.principal ?= "HTTP/#{node.fqdn}"
        unless typeof options.tls.subject is 'string'
          options.tls.subject ?= {}
          options.tls.subject.CN ?= "#{node.fqdn}"
          options.tls.subject = [
            "CN=#{options.tls.subject.CN}"
            "O=#{options.tls.subject.O}" if options.tls.subject.O
          ].join ','

## Client command

      if ipa_server
        options.admin ?= mixme ipa_server.options.ntp_enabled, options.admin

## Wait

      options.wait = {}

## Dependencies

    mixme = require 'mixme'
