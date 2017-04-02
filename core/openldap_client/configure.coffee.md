
# OpenLDAP Client Configure

```

```

    module.exports = ->
      openldap_server_ctxs = @contexts 'masson/core/openldap_server'
      openldap_client = @config.openldap_client ?= {}
      openldap_client.certificates ?= []
      openldap_client.certificates = for cert in openldap_client.certificates
        cert = name: cert if typeof cert is 'string'
        cert.local ?= false
        cert
      openldap_client.config ?= {}
      uris = for openldap_server_ctx in openldap_server_ctxs
        openldap_server_ctx.config.openldap_server.uri
      openldap_client.config['BASE'] ?= openldap_server_ctxs[0].config.openldap_server.suffix
      openldap_client.config['URI'] ?= uris.join ' '
      openldap_client.config['TLS_CACERTDIR'] ?= '/etc/openldap/cacerts'
      openldap_client.config['TLS_REQCERT'] ?= 'allow' # Allow self-signed certificates, use "demand" otherwise
      openldap_client.config['TIMELIMIT'] ?= '15'
      openldap_client.config['TIMEOUT'] ?= '20'
