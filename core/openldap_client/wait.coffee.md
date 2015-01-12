
# OpenLDAP Client Wait

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push require('./index').configure

## Wait

    exports.push name: 'OpenLDAP Client # Wait', timeout: -1, label_true: 'READY', callback: (ctx, next) ->
      {config} = ctx.config.openldap_client
      each(config['URI'].split ' ')
      .on 'item', (uri, next) ->
        uri = url.parse uri
        return next() if ['ldap:', 'ldaps:'].indexOf(uri.protocol) is -1
        uri.port ?= 389 if uri.protocol is 'ldap:'
        uri.port ?= 636 if uri.protocol is 'ldaps:'
        ctx.waitIsOpen uri.hostname, uri.port, next
      .on 'both', (err) ->
        next err, true

## Module Dependencies

    each = require 'each'
    url = require 'url'