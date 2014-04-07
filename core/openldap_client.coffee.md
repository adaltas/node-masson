---
title: 
layout: module
---

# OpenLDAP Client

    url = require 'url'
    each = require 'each'
    {merge} = require 'mecano/lib/misc'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/yum'

Install and configure the OpenLDAP client utilities. The
file "/etc/openldap/ldap.conf" is configured by the "openldap_client.config"
object property. The property "openldap\_client.ca\_cert" define the 
certificate upload if not null.

SSL certifcate could be defined in "/etc/ldap.conf" by 
the "TLS\_CACERT" or the "TLS\_CACERTDIR" properties. When 
using "TLS_CACERTDIR", the name of the file  must be the 
certicate hash with a numeric suffix. Here's an example 
showing how to place the certificate inside "TLS\_CACERTDIR":

```bash
hash=`openssl x509 -noout -hash -in cert.pem`
mv cert.pem /etc/openldap/cacerts/$hash.0
```

    module.exports.push (ctx) ->
      require('./openldap_server').configure ctx
      openldap_server = ctx.hosts_with_module 'masson/core/openldap_server'
      openldap_server_secured = ctx.hosts_with_module 'masson/core/openldap_server_tls'
      ctx.config.openldap_client ?= {}
      ctx.config.openldap_client.config ?= {}
      ctx.config.openldap_client.config['BASE'] ?= ctx.config.openldap_server.suffix
      ctx.config.openldap_client.config['URI'] ?= "ldaps://#{openldap_server_secured[0]}" if openldap_server_secured.length
      ctx.config.openldap_client.config['URI'] ?= "ldap://#{openldap_server[0]}" if openldap_server.length
      # ctx.config.openldap_client.config['TLS_CACERT'] = '/etc/pki/tls/certs/openldap.hadoop.cer'
      ctx.config.openldap_client.config['TLS_REQCERT'] = 'allow'
      ctx.config.openldap_client.config['TIMELIMIT'] = '15'
      ctx.config.openldap_client.config['TIMEOUT'] = '20'
      ctx.config.openldap_client.ca_cert ?= null
      if ctx.config.openldap_client.ca_cert
        ctx.config.openldap_client.config['TLS_CACERT'] ?= ctx.config.openldap_client.ca_cert.destination

    module.exports.push name: 'OpenLDAP Client # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service
        name: 'openldap-clients'
      , (err, installed) ->
        next err, if installed then ctx.OK else ctx.PASS

    module.exports.push name: 'OpenLDAP Client # Configure', timeout: -1, callback: (ctx, next) ->
      {config} = ctx.config.openldap_client
      write = []
      for k, v of config
        v = v.join(' ') if Array.isArray v
        write.push
          match: new RegExp "^#{k}.*$", 'mg'
          replace: "#{k} #{v}"
          append: true
      ctx.write
        write: write
        destination: '/etc/openldap/ldap.conf'
      , (err, written) ->
        next err, if written then ctx.OK else ctx.PASS

    module.exports.push name: 'OpenLDAP Client # Upload certificate', timeout: -1, callback: (ctx, next) ->
      {ca_cert} = ctx.config.openldap_client
      return next null, ctx.DISABLED unless ca_cert
      ctx.upload ca_cert, (err, uploaded) ->
        next err, if uploaded then ctx.OK else ctx.PASS

    module.exports.push name: 'OpenLDAP Client # Check URI', timeout: -1, callback: (ctx, next) ->
      {config} = ctx.config.openldap_client
      uris = []
      for k, v of config
        continue unless k.toLowerCase() is 'uri'
        for uri in v.split(' ') then uris.push uri
      each(uris)
      .on 'item', (uri, next) ->
        uri = url.parse uri
        return next() if ['ldap:', 'ldaps:'].indexOf(uri.protocol) is -1
        uri.port ?= 389 if uri.protocol is 'ldap:'
        uri.port ?= 636 if uri.protocol is 'ldaps:'
        ctx.waitIsOpen uri.hostname, uri.port, next
      .on 'both', (err) ->
        next err, ctx.PASS

    module.exports.push name: 'OpenLDAP Client # Check Search', callback: (ctx, next) ->
      {suffix, root_dn, root_password} = ctx.config.openldap_server
      return next null, ctx.INAPPLICABLE unless suffix
      ctx.execute
        cmd: "ldapsearch -x -D #{root_dn} -w #{root_password} -b '#{suffix}'"
      , (err, executed) ->
        next err, ctx.PASS

    module.exports.push name: 'OpenLDAP Client # PAM Services', callback: (ctx, next) ->
      {suffix, root_dn, root_password} = ctx.config.openldap_server
      return next null, ctx.INAPPLICABLE unless suffix
      ctx.service [
        name: 'nss-pam-ldapd'
      ,
        name: 'pam_ldap'
      ]
      , (err, executed) ->
        next err, ctx.PASS

    module.exports.push name: 'OpenLDAP Client # PAM Configuration', callback: (ctx, next) ->
      {suffix, root_dn, root_password} = ctx.config.openldap_server
      return next null, ctx.INAPPLICABLE unless suffix
      ctx.service [
        name: 'nss-pam-ldapd'
      ,
        name: 'pam_ldap'
      ]
      , (err, executed) ->
        next err, ctx.PASS



