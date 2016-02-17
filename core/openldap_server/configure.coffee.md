  
# OpenLDAP Server Configure

The property "openldap_server.config_slappasswd" may be generated with the command `slappasswd` 
and should correspond to "openldap_server.config_password".

    module.exports = handler: ->
      # require('../openldap_client').call @
      # Todo: Generate '*_slappasswd' with command `slappasswd -s $password`, but only the first time, we
      # need a mechanism to store configuration properties before.
      openldap_server = @config.openldap_server ?= {}
      throw new Error "Missing \"openldap_server.suffix\" property" unless openldap_server.suffix
      throw new Error "Missing \"openldap_server.root_password\" property" unless openldap_server.root_password
      # throw new Error "Missing \"openldap_server.root_slappasswd\" property" unless openldap_server.root_slappasswd
      throw new Error "Missing \"openldap_server.config_dn\" property" unless openldap_server.config_dn
      throw new Error "Missing \"openldap_server.config_password\" property" unless openldap_server.config_password
      {suffix} = openldap_server
      openldap_server.root_dn ?= "cn=Manager,#{openldap_server.suffix}"
      openldap_server.log_level ?= 256
      openldap_server.users_dn ?= "ou=users,#{suffix}"
      openldap_server.groups_dn ?= "ou=groups,#{suffix}"
      openldap_server.ldapadd ?= []
      openldap_server.ldapdelete ?= []
      openldap_server.tls ?= false
      openldap_server.config_file ?= '/etc/openldap/slapd.d/cn=config/olcDatabase={0}config.ldif'
      openldap_server.monitor_file ?= '/etc/openldap/slapd.d/cn=config/olcDatabase={1}monitor.ldif'
      openldap_server.bdb_file ?= '/etc/openldap/slapd.d/cn=config/olcDatabase={2}bdb.ldif'
      if openldap_server.tls
        throw Error 'TLS mode requires "tls_cert_file"' unless openldap_server.tls_cert_file
        throw Error 'TLS mode requires "tls_key_file"' unless openldap_server.tls_key_file
        openldap_server.uri = "ldaps://#{@config.host}"
      else
        openldap_server.uri = "ldap://#{@config.host}"
