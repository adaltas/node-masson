---
title: 
layout: module
---

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/openldap_server'

# OpenLDAP ACL

    module.exports.push (ctx) ->
      # Register "ctx.ldap_add" function
      require('./openldap_server').configure ctx
      {openldap_server} = ctx.config
      # require('./openldap_client_security').configure ctx
      # Obtain an ldap connection
      # require('./openldap_connection').configure ctx, next
      throw Error 'Missing required "openldap_server.users_dn" property' unless openldap_server.users_dn
      throw Error 'Missing required "openldap_server.groups_dn" property' unless openldap_server.groups_dn

After this call, the follwing command should execute with success:

```bash
ldapsearch -H ldap://master3.hadoop:389 -D cn=nssproxy,ou=users,dc=adaltas,dc=com -w test
```

    module.exports.push name: 'OpenLDAP ACL # Permissions for nssproxy', callback: (ctx, next) ->
      {suffix} = ctx.config.openldap_server
      ctx.ldap_acl
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
      , next

    module.exports.push name: 'OpenLDAP ACL # Insert User', callback: (ctx, next) ->
      {users_dn, groups_dn} = ctx.config.openldap_server
      ctx.ldap_add ctx, """
      dn: cn=nssproxy,#{users_dn}
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

      # dn: cn=test,#{users_dn}
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

      dn: cn=nssproxy,#{groups_dn}
      cn: nssproxy
      objectClass: top
      objectClass: posixGroup
      gidNumber: 801
      description: Network Service Switch Proxy

      # dn: cn=test,#{groups_dn}
      # cn: test.group
      # objectClass: top
      # objectClass: posixGroup
      # gidNumber: 1101
      # description: Test Group
      """, next

      







