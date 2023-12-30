
import {merge} from 'mixme'

export default ({options, node, deps}) ->
  options.fqdn = node.fqdn
  ipa_server = if deps.ipa_server?.length then deps.ipa_server[0] else null
  # Modules
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
  # SSL/TLS
  options.ssl ?= {}
  if options.ssl.enabled
    options.ssl.cacert ?= '/etc/ipa/ca.crt' # Exported to other services
    options.ssl.cert ?= '/etc/ipa/cert.pem'
    options.ssl.key ?= '/etc/ipa/key.pem'
    options.ssl.principal ?= "HTTP/#{node.fqdn}"
    unless typeof options.ssl.subject is 'string'
      options.ssl.subject ?= {}
      options.ssl.subject.CN ?= "#{node.fqdn}"
      options.ssl.subject = [
        "CN=#{options.ssl.subject.CN}"
        "O=#{options.ssl.subject.O}" if options.ssl.subject.O
      ].join ','
  # Client command
  if ipa_server
    options.admin ?= merge ipa_server.options.ntp_enabled, options.admin
  # Kerberos
  options.krb5_conf ?= {}
  options.krb5_conf.enabled ?= false
  options.krb5_conf.content ?= {}
  options.krb5_conf.merge ?= false
  options.krb5_conf.backup ?= true
  # Wait
  options.wait = {}
