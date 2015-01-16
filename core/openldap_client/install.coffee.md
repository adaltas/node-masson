
# OpenLDAP Client Install

Install and configure the OpenLDAP client utilities. The
file "/etc/openldap/ldap.conf" is configured by the "openldap_client.config"
object property. The property "openldap\_client.ca\_cert" may reference a 
certificate to upload.

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/bootstrap/utils'
    exports.push 'masson/core/yum'
    exports.push require('./index').configure

    exports.push name: 'OpenLDAP Client # Install', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'openldap-clients'
      , next

    exports.push name: 'OpenLDAP Client # Configure', timeout: -1, handler: (ctx, next) ->
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
        eof: true # was 4 lines up in write.push
      , next

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

    exports.push name: 'OpenLDAP Client # Certificate', timeout: -1, handler: (ctx, next) ->
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
        next err, modified

## Module Dependencies

    each = require 'each'
    crypto = require 'crypto'
