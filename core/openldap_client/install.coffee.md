
# OpenLDAP Client Install

Install and configure the OpenLDAP client utilities. The
file "/etc/openldap/ldap.conf" is configured by the "openldap_client.config"
object property. The property "openldap\_client.ca\_cert" may reference a 
certificate to upload.

    module.exports = header: 'OpenLDAP Client Install', handler: ->

## Package

      @service name: 'openldap-clients'

## Configuration

      {openldap_client} = @config
      @file
        header: 'Configure'
        write: for k, v of openldap_client.config
          v = v.join(' ') if Array.isArray v
          match: new RegExp "^#{k}.*$", 'mg'
          replace: "#{k} #{v}"
          append: true
        target: '/etc/openldap/ldap.conf'
        eof: true

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

Important, when changing the certificate for a server, we had to remove the old
certificate, not sure why.

Certificates are temporarily uploaded to the "/tmp" folder and registered with
the command `authconfig --update --ldaploadcacert={file}`.

      @call header: 'Certificate', handler: ->
        for certificate in openldap_client.certificates then do (certificate) =>
          filename = null
          if certificate.local
            hash = crypto.createHash('md5').update(certificate.source).digest('hex')
            @file.download
              source: certificate.source
              target: "/tmp/#{hash}"
              mode: 0o0640
              shy: true
            @system.execute # openssh is executed remotely
              cmd: "openssl x509 -noout -hash -in /tmp/#{hash}; rm -rf /tmp/#{hash}"
              shy: true
            , (err, _, stdout) ->
              filename = stdout.trim() unless err
            @call ->
              @file
                source: certificate.source
                local: true
                target: "#{openldap_client.config.TLS_CACERTDIR}/#{filename}.0"
          else
            @system.execute # openssh is executed remotely
              cmd: "openssl x509 -noout -hash -in #{certificate.source}"
              shy: true
            , (err, _, stdout) ->
              filename = stdout.trim() unless err
            @call ->
              @file
                source: certificate.source
                target: "#{openldap_client.config.TLS_CACERTDIR}/#{filename}.0"

## Dependencies

    crypto = require 'crypto'
    each = require 'each'
