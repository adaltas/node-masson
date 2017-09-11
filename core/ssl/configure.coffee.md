
# SSL Configure

## Example

```json
{ "ssl": {
    "cacert": "/path/to/remote/certificate_authority",
    "cert": "/path/to/remote/certificate",
    "key": "/path/to/remote/private_key"
} }
```

    module.exports = ->
      service = migration.call @, service, 'masson/core/ssl', ['ssl'], require('nikita/lib/misc').merge require('.').use,
        java: key: ['java']
      options = @config.ssl = service.options

## CA Certiticate

      options.cacert = source: options.cacert, local: false if typeof options.cacert is 'string'
      if options.cacert?.target
        options.cacert.target = "ca.cert.pem" if options.cacert.target is true
        throw Error "Invalid Target" unless typeof options.cacert.target is 'string'
        options.cacert.target = path.resolve '/etc/security/certs', options.cacert.target

## Public Certificate

      options.cert = source: options.cert, local: false if typeof options.cert is 'string'
      if options.cert?.target
        options.cert.target = "#{@config.shortname}.cert.pem" if options.cert.target is true
        throw Error "Invalid Target" unless typeof options.cert.target is 'string'
        options.cert.target = path.resolve '/etc/security/certs', options.cert.target

## Private Key

      options.key = source: options.key, local: false if typeof options.key is 'string'
      if options.key?.target
        options.key.target = "#{@config.shortname}.key.pem" if options.key.target is true
        throw Error "Invalid Target" unless typeof options.key.target is 'string'
        options.key.target = path.resolve '/etc/security/certs', options.key.target
      options.key.name ?= service.node.hostname

## JKS Truststore

      options.truststore ?= disabled: true
      unless options.truststore.disabled
        throw Error "Required Option: options.cacert" unless options.cacert
        options.truststore.target ?= path.resolve '/etc/security/jks', 'truststore.jks'
        options.truststore.caname ?= "ryba_root_ca"
        throw Error "Required options: options.truststore.password" unless options.truststore.password

## JKS Keystore

The final keystore object will look like:

```
{
  "target": "/etc/security/jks/keystore.jks",
  "name": "{current hostname}",
  "caname": "ryba_root_ca",
  "password": "{required user password}",
  "keypass": "{often same as password}"
}
```

To create the keystore, the certificate paths are retrieved from the "ssl"
option. 

In Tomcat servers, the key password must match the keystore password. This is confirmed by the 
[Tomcat documentation](https://tomcat.apache.org/tomcat-6.0-doc/ssl-howto.html#Prepare_the_Certificate_Keystore) 
which state: "You MUST use the same password here as was used for the keystore 
password itself. This is a restriction of the Tomcat implementation."

      options.keystore ?= disabled: true
      unless options.keystore.disabled
        throw Error "Required Option: options.key" unless options.key
        throw Error "Required Option: options.cert" unless options.cert
        options.keystore.target ?= path.resolve '/etc/security/jks', 'keystore.jks'
        options.keystore.name ?= service.node.hostname
        options.keystore.caname ?= "ryba_root_ca"
        throw Error "Required options: options.keystore.password" unless options.keystore.password
        throw Error "Required options: options.keystore.keypass" unless options.keystore.keypass

## Dependencies

    path = require('path').posix
    migration = require '../../lib/migration'
