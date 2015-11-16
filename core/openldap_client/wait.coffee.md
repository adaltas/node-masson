
# OpenLDAP Client Wait

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    # exports.push require('./index').configure

## Wait

    exports.push header: 'OpenLDAP Client # Wait', timeout: -1, label_true: 'READY', handler: ->
      {config} = @config.openldap_client
      for uri in config['URI'].split ' '
        uri = url.parse uri
        continue if ['ldap:', 'ldaps:'].indexOf(uri.protocol) is -1
        uri.port ?= 389 if uri.protocol is 'ldap:'
        uri.port ?= 636 if uri.protocol is 'ldaps:'
        @wait_connect
          host: uri.hostname
          port: uri.port

## Dependencies

    url = require 'url'
