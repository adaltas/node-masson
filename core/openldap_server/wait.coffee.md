
# OpenLDAP Server Wait

Wait for all the OpenLDAP servers deployed by Masson.

## Wait TCP

    module.exports = header: 'OpenLDAP Server Wait', timeout: -1, label_true: 'READY', handler: ->
      @connection.wait
        header: 'TCP'
        servers: for ldap_srv in @contexts 'masson/core/openldap_server'
          port = if ldap_srv.config.openldap_server.tls then 389 else 636
          host: ldap_srv.config.host, port: port
