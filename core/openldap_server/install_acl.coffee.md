
# OpenLDAP ACL

    export default header: 'OpenLDAP Server ACL', handler: ({options}) ->

After this call, the follwing command should execute with success:

```bash
ldapsearch -H ldap://master3.hadoop:389 -D cn=nssproxy,ou=users,dc=adaltas,dc=com -w test
```

      @call header: 'ACL for nssproxy', handler: ->
        @ldap.acl
          suffix: options.suffix
          acls: [
            to: 'attrs=userPassword,userPKCS12'
            by: [
              'dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage'
              "dn.exact=\"cn=nssproxy,ou=users,#{options.suffix}\" read"
              'self write'
              'anonymous auth'
              '* none'
            ]
          ,
            to: 'attrs=shadowLastChange'
            by: [
              'self write'
              'dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage'
              "dn.exact=\"cn=nssproxy,ou=users,#{options.suffix}\" read"
              '* none'
            ]
          ,
            to: "dn.subtree=\"#{options.suffix}\""
            by: [
              "dn.exact=\"cn=nssproxy,ou=users,#{options.suffix}\" read"
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
        @ldap.user
          uri: options.uri
          binddn: options.root_dn
          passwd: options.root_password
          user: options.proxy_user

      @call header: 'ACL Insert Group', handler: ->
        @ldap.add
          uri: options.uri,
          binddn: options.root_dn
          passwd: options.root_password
          entry: options.proxy_group
