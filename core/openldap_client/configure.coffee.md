
# OpenLDAP Client Configure

    module.exports = handler: ->
      config = @config.openldap_client ?= {}
      @config.openldap_client.config ?= {}
      @config.openldap_client.certificates ?= []
      openldap_server_ctxs = @contexts 'masson/core/openldap_server'
      # openldap_server = @hosts_with_module 'masson/core/openldap_server'
      if openldap_server_ctxs.length isnt 1
        openldap_server_ctxs = openldap_server_ctxs.filter (ctx) -> ctx.config.host is @config.host
      openldap_server_ctx = if openldap_server_ctxs.length is 1 then openldap_server_ctxs[0] else null
      openldap_servers_secured_ctxs = @contexts 'masson/core/openldap_server/install_tls'
      uris = {}
      for ctx in openldap_server_ctxs then uris[ctx.config.host] = "ldap://#{ctx.config.host}"
      for ctx in openldap_servers_secured_ctxs then uris[ctx.config.host] = "ldaps://#{ctx.config.host}"
      uris = for _, uri of uris then uri
      if openldap_server_ctx
        # require('../openldap_server').configure openldap_server_ctx
        config.config['BASE'] ?= openldap_server_ctx.config.openldap_server.suffix
        config.suffix ?= openldap_server_ctx.config.openldap_server.suffix
        config.root_dn ?= openldap_server_ctx.config.openldap_server.root_dn
        config.root_password ?= openldap_server_ctx.config.openldap_server.root_password
      config.config['URI'] ?= uris.join ' '
      config.config['TLS_CACERTDIR'] ?= '/etc/openldap/cacerts'
      config.config['TLS_REQCERT'] ?= 'allow' # Allow self-signed certificates, use "demand" otherwise
      config.config['TIMELIMIT'] ?= '15'
      config.config['TIMEOUT'] ?= '20'
