
# OpenLDAP Client Wait

    module.exports = header: 'OpenLDAP Client Wait', timeout: -1, label_true: 'READY', handler: ->
      for openldap_ctx in @contexts 'masson/core/openldap_server'
        {openldap_client} = openldap_ctx.config
        for uri in openldap_client.config['URI'].split ' '
          uri = url.parse uri
          continue if ['ldap:', 'ldaps:'].indexOf(uri.protocol) is -1
          uri.port ?= 389 if uri.protocol is 'ldap:'
          uri.port ?= 636 if uri.protocol is 'ldaps:'
          @wait_connect
            host: uri.hostname
            port: uri.port

## Dependencies

    url = require 'url'
