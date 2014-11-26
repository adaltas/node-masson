
# OpenLDAP Client Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Wait

    module.exports.push name: 'OpenLDAP Client # Wait', timeout: -1, callback: (ctx, next) ->
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