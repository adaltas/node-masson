---
title: 
layout: module
---

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/openldap_server'

# OpenLDAP ACL

    module.exports.push (ctx, next) ->
      # Register "ctx.ldap_add" function
      require('./openldap_server').configure ctx
      require('./openldap_client_security').configure ctx
      # Obtain an ldap connection
      require('./openldap_connection').configure ctx, next

After this call, the follwing command should execute with success:

```bash
ldapsearch -H ldap://master3.hadoop:389 -D cn=nssproxy,ou=users,dc=adaltas,dc=com -w test
```

    module.exports.push name: 'OpenLDAP ACL # Permissions for nssproxy', callback: (ctx, next) ->
      {suffix} = ctx.config.openldap_server
      ctx.ldap_acl
        ldap: ctx.ldap_config
        name: 'olcDatabase={2}bdb,cn=config'
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
      , (err, modified) ->
        next err, if modified then ctx.OK else ctx.PASS

    module.exports.push name: 'OpenLDAP ACL # Insert User', callback: (ctx, next) ->
      {users_container_dn, groups_container_dn} = ctx.config.openldap_client_security
      ctx.ldap_add ctx, """
      dn: cn=nssproxy,#{users_container_dn}
      uid: nssproxy
      gecos: Network Service Switch Proxy User
      objectClass: top
      objectClass: account
      objectClass: posixAccount
      objectClass: shadowAccount
      userPassword: {SSHA}uQcSsw5CySTkBXjOY/N0hcduA6yFiI0k
      shadowLastChange: 15140
      shadowMin: 0
      shadowMax: 99999
      shadowWarning: 7
      loginShell: /bin/false
      uidNumber: 801
      gidNumber: 801
      homeDirectory: /home/nssproxy

      # dn: cn=test,#{users_container_dn}
      # uid: test
      # gecos: Test User
      # objectClass: top
      # objectClass: account
      # objectClass: posixAccount
      # objectClass: shadowAccount
      # userPassword: {SSHA}uQcSsw5CySTkBXjOY/N0hcduA6yFiI0k
      # shadowLastChange: 15140
      # shadowMin: 0
      # shadowMax: 99999
      # shadowWarning: 7
      # loginShell: /bin/bash
      # uidNumber: 1101
      # gidNumber: 1101
      # homeDirectory: /home/test

      dn: cn=nssproxy,#{groups_container_dn}
      cn: nssproxy
      objectClass: top
      objectClass: posixGroup
      gidNumber: 801
      description: Network Service Switch Proxy

      # dn: cn=test,#{groups_container_dn}
      # cn: test.group
      # objectClass: top
      # objectClass: posixGroup
      # gidNumber: 1101
      # description: Test Group
      """, (err, added) ->
        next err, if added then ctx.OK else ctx.PASS

      







