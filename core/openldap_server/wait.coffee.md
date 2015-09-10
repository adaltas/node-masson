
# OpenLDAP Server Wait

Wait for all the OpenLDAP servers deployed by Masson.

## Preparation

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Wait TCP

    exports.push name: 'OpenLDAP Server # Wait TCP', timeout: -1, label_true: 'READY', handler: ->
      @wait_connect
        servers: for ldap_srv in @contexts 'masson/core/openldap_server'
          port = if ldap_srv.config.openldap_server.tls then 389 else 636
          host: ldap_srv.config.host, port: port
