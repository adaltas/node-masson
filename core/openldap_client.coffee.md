---
title: 
layout: module
---

# OpenLDAP Client

Install and configure the OpenLDAP client utilities. The
file "/etc/openldap/ldap.conf" is configured by the "openldap_client.config"
object property. The property "openldap\_client.ca\_cert" may reference a 
certificate to upload.

    url = require 'url'
    each = require 'each'
    crypto = require 'crypto'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/yum'

## Configuration

*   `openldap_client.config` (object)   
    Configuration of the "/etc/openldap/ldap.conf" file.   
*   `openldap_client.config.TLS_CACERTDIR` (string)   
    Default to "/etc/openldap/cacerts".   
*   `openldap_client.config.TLS_REQCERT` (string)   
    Default to "allow".   
*   `openldap_client.config.TIMELIMIT` (string|number)   
    Default to "15".   
*   `openldap_client.config.TIMEOUT` (string|number)  
    Default to "10".    
*   `openldap_client.suffix` (string)   
    LDAP suffix used by the test, default to null or discovered.   
*   `openldap_client.root_dn` (string)   
    LDAP user used by the test, default to null or discovered.   
*   `openldap_client.root_password` (string)   
    LDAP password used by the test, default to null or discovered.   
*   `openldap_client.certificates` (array)   
    Paths to the certificates to upload.   

The properties `openldap_client.config.BASE`, `openldap_client.suffix`, 
`openldap_client.root_dn` and `openldap_client.root_password` are discovered if 
there is only one LDAP server or if an LDAP server is deployed on the same 
server.

The property `openldap_client.config.URI` is generated with the list of 
configured LDAP servers.

Example:

```json
{
  "openldap_client": {
    "config": {
      "TLS_REQCERT": "allow",
      "TIMELIMIT": "15".
      "TIMEOUT": "10"
    },
    "certificates": [
      "./cert.pem"
    ]
  }
}
```

    module.exports.push module.exports.configure = (ctx) ->
      config = ctx.config.openldap_client ?= {}
      ctx.config.openldap_client.config ?= {}
      openldap_servers = ctx.hosts_with_module 'masson/core/openldap_server'
      # openldap_server = ctx.hosts_with_module 'masson/core/openldap_server'
      if openldap_servers.length isnt 1
        openldap_servers = openldap_servers.filter (server) -> server is ctx.config.host
      openldap_server = if openldap_servers.length is 1 then openldap_servers[0] else null
      openldap_servers_secured = ctx.hosts_with_module 'masson/core/openldap_server_tls'
      uris = {}
      for server in openldap_servers then uris[server] = "ldap://#{server}"
      for server in openldap_servers_secured then uris[server] = "ldaps://#{server}"
      uris = for _, uri of uris then uri
      if openldap_server
        ctx_server = ctx.hosts[openldap_server]
        require('./openldap_server').configure ctx_server
        config.config['BASE'] ?= ctx_server.config.openldap_server.suffix
        config.suffix ?= ctx_server.config.openldap_server.suffix
        config.root_dn ?= ctx_server.config.openldap_server.root_dn
        config.root_password ?= ctx_server.config.openldap_server.root_password
      config.config['URI'] ?= uris.join ' '
      config.config['TLS_CACERTDIR'] ?= '/etc/openldap/cacerts'
      config.config['TLS_REQCERT'] ?= 'allow'
      config.config['TIMELIMIT'] ?= '15'
      config.config['TIMEOUT'] ?= '20'

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
          eof: true
      ctx.write
        write: write
        destination: '/etc/openldap/ldap.conf'
      , (err, written) ->
        next err, if written then ctx.OK else ctx.PASS

## Upload certificate

SSL certifcate could be defined in "/etc/ldap.conf" by 
the "TLS\_CACERT" or the "TLS\_CACERTDIR" properties. When 
using "TLS_CACERTDIR", the name of the file  must be the 
certicate hash with a numeric suffix. Here's an example 
showing how to place the certificate inside "TLS\_CACERTDIR":

```bash
hash=`openssl x509 -noout -hash -in cert.pem`
mv cert.pem /etc/openldap/cacerts/$hash.0
```

Certificates are temporarily uploaded to the "/tmp" folder and registered with
the command `authconfig --update --ldaploadcacert={file}`.

    module.exports.push name: 'OpenLDAP Client # Certificate', timeout: -1, callback: (ctx, next) ->
      {certificates, config} = ctx.config.openldap_client
      modified = false
      each(certificates)
      .on 'item', (certificate, next) ->
        hash = crypto.createHash('md5').update(certificate).digest('hex')
        ctx.upload
          source: certificate
          destination: "/tmp/#{hash}"
        , (err) ->
          return next err if err
          ctx.execute # openssh is executed remotely
            cmd: "openssl x509 -noout -hash -in /tmp/#{hash}; rm -rf /tmp/#{hash}"
          , (err, _, stdout) ->
            return next err if err
            stdout = stdout.trim()
            ctx.upload 
              source: certificate
              destination: "#{config.TLS_CACERTDIR}/#{stdout}.0"
            , (err, uploaded) ->
              return next err if err
              modified = true if uploaded
              next()
      .on 'both', (err) ->
        next err, if modified then ctx.OK else ctx.PASS

    module.exports.push name: 'OpenLDAP Client # Check URI', timeout: -1, callback: (ctx, next) ->
      {config} = ctx.config.openldap_client
      each(config['URI'].split ' ')
      .on 'item', (uri, next) ->
        uri = url.parse uri
        return next() if ['ldap:', 'ldaps:'].indexOf(uri.protocol) is -1
        uri.port ?= 389 if uri.protocol is 'ldap:'
        uri.port ?= 636 if uri.protocol is 'ldaps:'
        ctx.waitIsOpen uri.hostname, uri.port, next
      .on 'both', (err) ->
        next err, ctx.PASS

    module.exports.push name: 'OpenLDAP Client # Check Search', callback: (ctx, next) ->
      {suffix, root_dn, root_password} = ctx.config.openldap_client
      return next() unless suffix
      ctx.execute
        cmd: "ldapsearch -x -D #{root_dn} -w #{root_password} -b '#{suffix}'"
      , (err, executed) ->
        next err, ctx.PASS
