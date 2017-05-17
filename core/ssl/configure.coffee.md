
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
      return unless @config.ssl
      @config.ssl = {} if @config.ssl is true
      options = @config.ssl
      options.cacert = source: options.cacert, local: false if typeof options.cacert is 'string'
      if options.cacert?.target
        options.cacert.target = "#{config.shortname}.cert.pem" if options.cacert.target is true
        options.cacert.target = path.resolve '/etc/security/certs' if options.cacert.target is 'string'
      options.cert = source: options.cert, local: false if typeof options.cert is 'string'
      if options.cert?.target
        options.cert.target = "#{config.shortname}.cert.pem" if options.cert.target is true
        options.cert.target = path.resolve '/etc/security/certs' if options.cert.target is 'string'
      options.key = source: options.key, local: false if typeof options.key is 'string'
      if options.key?.target
        options.key.target = "#{config.shortname}.cert.pem" if options.key.target is true
        options.key.target = path.resolve '/etc/security/certs' if options.key.target is 'string'
