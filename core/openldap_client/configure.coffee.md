
# OpenLDAP Client Configure

```

```

    module.exports = ->
      openldap_server_ctxs = @contexts 'masson/core/openldap_server'
      options = @config.openldap_client ?= {}
      options.certificates ?= []
      options.certificates = for cert in options.certificates
        cert = source: cert if typeof cert is 'string'
        cert.local ?= false
        cert
      options.config ?= {}
      uris = for openldap_server_ctx in openldap_server_ctxs
        openldap_server_ctx.config.openldap_server.uri
      options.config['BASE'] ?= openldap_server_ctxs[0].config.openldap_server.suffix
      options.config['URI'] ?= uris.join ' '
      options.config['TLS_CACERTDIR'] ?= '/etc/openldap/cacerts'
      options.config['TLS_REQCERT'] ?= 'demand' # Allow self-signed certificates, use "demand" otherwise
      options.config['TIMELIMIT'] ?= '15'
      options.config['TIMEOUT'] ?= '20'
