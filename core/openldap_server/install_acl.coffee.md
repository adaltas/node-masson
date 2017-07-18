
# OpenLDAP ACL

    module.exports = header: 'OpenLDAP Server ACL', handler: ->

After this call, the follwing command should execute with success:

```bash
ldapsearch -H ldap://master3.hadoop:389 -D cn=nssproxy,ou=users,dc=adaltas,dc=com -w test
```

      {kerberos_dn, krbadmin_user, krbadmin_group} = @config.openldap_server_krb5
      {openldap_server} = @config

      @call header: 'ACL for nssproxy', handler: ->
        {suffix} = @config.openldap_server
        @ldap.acl
          suffix: suffix
          acls: [
            to: 'attrs=userPassword,userPKCS12'
            by: [
              'dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage'
              "dn.exact=\"cn=nssproxy,ou=users,#{suffix}\" read"
              'self write'
              'anonymous auth'
              '* none'
            ]
          ,
            to: 'attrs=shadowLastChange'
            by: [
              'self write'
              'dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage'
              "dn.exact=\"cn=nssproxy,ou=users,#{suffix}\" read"
              '* none'
            ]
          ,
            to: "dn.subtree=\"#{suffix}\""
            by: [
              "dn.exact=\"cn=nssproxy,ou=users,#{suffix}\" read"
              '* none'
            ]
          ]

      @call header: 'ACL Insert User', handler: ->
        # Keeping this as an example but we dont need it here since this module
        # is always run next to the OpenLDAP server
        # host = @host_with_module 'masson/core/openldap_server'
        # host_ctx = @hosts[host]
        # require('./openldap_server').configure host_ctx
        # {url, root_dn, root_password, users_dn, groups_dn} = host_@config.openldap_server
        {openldap_server} = @config
        @ldap.user
          uri: openldap_server.uri
          binddn: openldap_server.root_dn
          passwd: openldap_server.root_password
          user: openldap_server.proxy_user

      @call header: 'ACL Insert Group', handler: ->
        {openldap_server} = @config
        @ldap.add
          uri: openldap_server.uri,
          binddn: openldap_server.root_dn
          passwd: openldap_server.root_password
          entry: openldap_server.proxy_group
