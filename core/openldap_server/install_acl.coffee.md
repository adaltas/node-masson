
    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/openldap_server/install'
    exports.push require('./index').configure

# OpenLDAP ACL

    exports.push (ctx) ->
      {openldap_server} = ctx.config
      throw Error 'Missing required "openldap_server.users_dn" property' unless openldap_server.users_dn
      throw Error 'Missing required "openldap_server.groups_dn" property' unless openldap_server.groups_dn
      openldap_server.proxy_user ?= {}
      openldap_server.proxy_user.dn ?= "cn=nssproxy,#{openldap_server.users_dn}"
      openldap_server.proxy_user.uid ?= 'nssproxy'
      openldap_server.proxy_user.gecos ?= 'Network Service Switch Proxy User'
      openldap_server.proxy_user.objectClass ?= ['top', 'account', 'posixAccount', 'shadowAccount']
      openldap_server.proxy_user.userPassword ?= 'test'
      openldap_server.proxy_user.shadowLastChange ?= '15140'
      openldap_server.proxy_user.shadowMin ?= '0'
      openldap_server.proxy_user.shadowMax ?= '99999'
      openldap_server.proxy_user.shadowWarning ?= '7'
      openldap_server.proxy_user.loginShell ?= '/bin/false'
      openldap_server.proxy_user.uidNumber ?= '801'
      openldap_server.proxy_user.gidNumber ?= '801'
      openldap_server.proxy_user.homeDirectory ?= '/home/nssproxy'
      openldap_server.proxy_group ?= {}
      openldap_server.proxy_group.dn ?= "cn=nssproxy,#{openldap_server.groups_dn}"
      openldap_server.proxy_group.objectClass ?= ['top', 'posixGroup']
      openldap_server.proxy_group.gidNumber ?= '801'
      openldap_server.proxy_group.description ?= 'Network Service Switch Proxy'

After this call, the follwing command should execute with success:

```bash
ldapsearch -H ldap://master3.hadoop:389 -D cn=nssproxy,ou=users,dc=adaltas,dc=com -w test
```

    exports.push name: 'OpenLDAP ACL # Permissions for nssproxy', handler: (ctx, next) ->
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

    exports.push name: 'OpenLDAP ACL # Insert User', handler: (ctx, next) ->
      # Keeping this as an example but we dont need it here since this module
      # is always run next to the OpenLDAP server
      # host = ctx.host_with_module 'masson/core/openldap_server'
      # host_ctx = ctx.hosts[host]
      # require('./openldap_server').configure host_ctx
      # {url, root_dn, root_password, users_dn, groups_dn} = host_ctx.config.openldap_server
      {openldap_server} = ctx.config
      ctx.ldap_user
        uri: openldap_server.uri,
        binddn: openldap_server.root_dn,
        passwd: openldap_server.root_password,
        user: openldap_server.proxy_user
      , next

    exports.push name: 'OpenLDAP ACL # Insert Group', handler: (ctx, next) ->
      {openldap_server} = ctx.config
      ctx.ldap_add
        uri: openldap_server.uri,
        binddn: openldap_server.root_dn,
        passwd: openldap_server.root_password,
        entry: openldap_server.proxy_group
      , next

      







