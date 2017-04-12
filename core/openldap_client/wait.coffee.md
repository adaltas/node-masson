
# OpenLDAP Client Wait

    module.exports = header: 'OpenLDAP Client Wait', timeout: -1, label_true: 'READY', handler: ->
      # for openldap_ctx in @contexts 'masson/core/openldap_server'
      #   for uri in openldap_ctx.config.openldap_client.config['URI'].split ' '
      #     uri = url.parse uri
      #     continue if ['ldap:', 'ldaps:'].indexOf(uri.protocol) is -1
      #     uri.port ?= switch uri.protocol
      #       when 'ldap:' then 389
      #       when 'ldaps:' then 636
      #     @connection.wait
      #       host: uri.hostname
      #       port: uri.port
      {openldap_client} = @config
      for uri in openldap_client.config['URI'].split ' '
        uri = url.parse uri
        throw Error "Invalid propotol: #{JSON.stringify uri.protocol}" unless uri.protocol in ['ldap:', 'ldaps:']
        uri.port ?= switch uri.protocol
          when 'ldap:' then 389
          when 'ldaps:' then 636
        @connection.wait
          host: uri.hostname
          port: uri.port

## Dependencies

    url = require 'url'
