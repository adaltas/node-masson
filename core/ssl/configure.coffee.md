
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
      shortname = @config.shortname
      options = @config.ssl ?= {}
      # CA Certiticate
      options.cacert = source: options.cacert, local: false if typeof options.cacert is 'string'
      if options.cacert?.target
        options.cacert.target = "ca.cert.pem" if options.cacert.target is true
        throw Error "Invalid Target" unless typeof options.cacert.target is 'string'
        options.cacert.target = path.posix.resolve '/etc/security/certs', options.cacert.target
      # Public Certificate
      options.cert = source: options.cert, local: false if typeof options.cert is 'string'
      if options.cert?.target
        options.cert.target = "#{config.shortname}.cert.pem" if options.cert.target is true
        throw Error "Invalid Target" unless typeof options.cert.target is 'string'
        options.cert.target = path.posix.resolve '/etc/security/certs', options.cert.target
      # Private Key
      options.key = source: options.key, local: false if typeof options.key is 'string'
      if options.key?.target
        options.key.target = "#{config.shortname}.key.pem" if options.key.target is true
        throw Error "Invalid Target" unless typeof options.key.target is 'string'
        options.key.target = path.posix.resolve '/etc/security/certs', options.key.target
      # JKS Truststore
      options.truststore ?= disabled: true
      unless options.truststore.disabled
        throw Error "Required Option: options.cacert" unless options.cacert
        options.truststore.target ?= path.posix.resolve '/etc/security/jks', 'truststore.jks'
        options.truststore.caname ?= "ryba_root_ca"
        throw Error "Required options: options.truststore.password" unless options.truststore.password
      # JKS Keystore
      options.keystore ?= disabled: true
      unless options.keystore.disabled
        throw Error "Required Option: options.key" unless options.key
        throw Error "Required Option: options.cert" unless options.cert
        options.keystore.target ?= path.posix.resolve '/etc/security/jks', 'keystore.jks'
        options.keystore.name ?= shortname
        options.keystore.caname ?= "ryba_root_ca"
        throw Error "Required options: options.keystore.password" unless options.keystore.password
        throw Error "Required options: options.keystore.keypass" unless options.keystore.keypass

## Dependencies

    path = require 'path'
