---
title: 
layout: module
---

# OpenLDAP Kerberos

    {check_password} = require './openldap_server'
    misc = require 'mecano/lib/misc'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Configuration

We make sure to set "ctx.ldap_admin" which isn't present in
force mode.

    module.exports.push module.exports.configure = (ctx) ->
      # Dependencies
      require('./openldap_server').configure ctx
      # require('./krb5_server').configure ctx
      # Normalization
      ctx.config.openldap_server_krb5 ?= {}
      {openldap_server, openldap_server_krb5} = ctx.config
      openldap_server_krb5.kerberos_dn ?= "ou=kerberos,#{openldap_server.suffix}"
      # Configure openldap_server_krb5
      # {admin_group, users_dn, groups_dn, admin_user} = openldap_server_krb5
      # User for krbadmin
      # Example: "dn: cn=krbadmin,ou=groups,dc=adaltas,dc=com"
      openldap_server_krb5.krbadmin_user ?= {}
      openldap_server_krb5.krbadmin_user = misc.merge {},
        dn: "cn=krbadmin,#{openldap_server.users_dn}"
        cn: 'krbadmin'
        objectClass: [
          'top', 'inetOrgPerson', 'organizationalPerson',
          'person', 'posixAccount'
        ]
        givenName: 'Kerberos Administrator'
        mail: 'kerberos.admin@company.com'
        sn: 'krbadmin'
        uid: 'krbadmin'
        uidNumber: '800'
        gidNumber: '800'
        homeDirectory: '/home/krbadmin'
        loginShell: '/bin/false'
        displayname: 'Kerberos Administrator'
        # userPassword: '{SSHA}uQcSsw5CySTkBXjOY/N0hcduA6yFiI0k' #test
        userPassword: 'test' #test
      , openldap_server_krb5.krbadmin_user
      # Group for krbadmin
      # Example: "dn: cn=krbadmin,ou=groups,dc=adaltas,dc=com"
      openldap_server_krb5.krbadmin_group ?= {}
      openldap_server_krb5.krbadmin_group = misc.merge {},
        dn: "cn=krbadmin,#{openldap_server.groups_dn}"
        cn: 'krbadmin'
        objectClass: [ 'top', 'posixGroup' ]
        gidNumber: '800'
        description: 'Kerberos administrator\'s group.'
      , openldap_server_krb5.krbadmin_group

## Install schema

Prepare and deploy the kerberos schema. Upon installation, it
is possible to check if the schema is installed by calling
the command `ldapsearch  -D cn=admin,cn=config -w test -b "cn=config"`.

    module.exports.push name: 'OpenLDAP Kerberos # Install schema', timeout: -1, callback: (ctx, next) ->
      conf = '/tmp/kerberos_schema/schema.conf'
      ldif = '/tmp/kerberos_schema/ldif'
      {config_dn, config_password} = ctx.config.openldap_server
      install = ->
        ctx.log 'Install schema'
        ctx.service
          name: 'krb5-server-ldap'
        , (err, serviced) ->
          return next err if err
          locate()
      locate = ->
        ctx.log 'Get schema location'
        ctx.execute
          cmd: 'rpm -ql krb5-server-ldap | grep kerberos.schema'
        , (err, executed, schema) ->
          return next err if err
          return next Error 'Sudo schema not found' if schema is ''
          register schema
      register = (schema) ->
        ctx.ldap_schema
          name: 'kerberos'
          schema: schema
          binddn: config_dn
          passwd: config_password
          log: ctx.log
        , next
      install()

## Insert Container

Create the kerberos organisational unit, for example 
"ou=kerberos,dc=adaltas,dc=com".

    module.exports.push name: 'OpenLDAP Kerberos # Insert Container', callback: (ctx, next) ->
      {kerberos_dn, krbadmin_user} = ctx.config.openldap_server_krb5
      ctx.ldap_add ctx, """
        dn: #{kerberos_dn}
        objectClass: top
        objectClass: organizationalUnit
        ou: #{/^ou=(.*?),/.exec(kerberos_dn)[1]}
        description: Kerberos OU to store Kerberos principals.
        """
      , next

## Insert Group

Create the kerberos administrator's group.

    module.exports.push name: 'OpenLDAP Kerberos # Insert Group', callback: (ctx, next) ->
      {krbadmin_group} = ctx.config.openldap_server_krb5
      ldif = ''
      for k, v of krbadmin_group
        v = [v] unless Array.isArray v
        for vv in v
          ldif += "#{k}: #{vv}\n"
      ctx.ldap_add ctx, ldif, next

# Insert Admin User

Create the kerberos administrator's user.

    module.exports.push name: 'OpenLDAP Kerberos # Insert Admin User', callback: (ctx, next) ->
      {kerberos_dn, krbadmin_user} = ctx.config.openldap_server_krb5
      modified = false
      do_krbadmin_user = ->
        ldif = ''
        for k, v of krbadmin_user
          continue if k is 'userPassword'
          v = [v] unless Array.isArray v
          for vv in v
            ldif += "#{k}: #{vv}\n"
        ctx.ldap_add ctx, ldif, (err, added) ->
          return next err if err
          modified = true if added
          do_krbadmin_user_password added
      do_krbadmin_user_password = (force) ->
        do_checkpass = ->
          ctx.execute
            cmd: """
              ldapsearch -H ldapi:/// \
                -D #{krbadmin_user.dn} -w #{krbadmin_user.userPassword} \
                -b '#{kerberos_dn}'
            """
            code_skipped: 1
          , (err, exists, stdout) ->
            if err then do_ldappass() else do_end()
        do_ldappass = ->
          ctx.execute
            cmd: """
            ldappasswd -H ldapi:/// \
              -D cn=Manager,dc=adaltas,dc=com -w test \
              '#{krbadmin_user.dn}' \
              -s #{krbadmin_user.userPassword}
            """
          , (err) ->
            return next err if err
            modified = true
            do_end()
        if force then do_ldappass() else do_checkpass()
      do_end = (err) ->
        next err, modified
      do_krbadmin_user()

    module.exports.push name: 'OpenLDAP Kerberos # User permissions', callback: (ctx, next) ->
      # We used: http://itdavid.blogspot.fr/2012/05/howto-centos-62-kerberos-kdc-with.html
      # But this is also interesting: http://web.mit.edu/kerberos/krb5-current/doc/admin/conf_ldap.html
      {kerberos_dn, krbadmin_user} = ctx.config.openldap_server_krb5
      {suffix} = ctx.config.openldap_server
      ctx.ldap_acl [
        suffix: suffix
        acls: [
        #   before: "dn.subtree=\"#{kerberos_dn}\""
        #   to: "attrs=userPassword,userPKCS12"
        #   by: [
        #     "dn.base=\"gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth\" manage "
        #     "self write  "
        #     "anonymous auth "
        #     "* none"
        #   ]
        # ,
          before: "dn.subtree=\"#{suffix}\""
          to: "dn.subtree=\"#{kerberos_dn}\""
          by: [
            "dn.exact=\"#{krbadmin_user.dn}\" write"
            "dn.base=\"gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth\" read"
            "* none"
          ]
        ,
          to: "dn.subtree=\"#{suffix}\""
          by: [
            "dn.exact=\"#{krbadmin_user.dn}\" write"
          ]
        ]
      ], (err, modified) ->
        return next err if err
        ctx.log "Check it returns the entire #{kerberos_dn} subtree"
        ctx.execute
          cmd: "ldapsearch -xLLLD #{krbadmin_user.dn} -w #{krbadmin_user.userPassword} -b #{kerberos_dn}"
        , (err) ->
          # Nice but no garanty that a "nssproxy" user exists. I keep it
          # for now because it would be great to test permission
          # return next err if err
          # ctx.log 'Check it return the « No such object (32) » error'
          # ldapsearch -xLLLD cn=nssproxy,ou=users,dc=adaltas,dc=com -w test -bou=kerberos,ou=services,dc=adaltas,dc=com dn
          # ctx.execute
          #   cmd: "ldapsearch -xLLLD cn=nssproxy,ou=users,dc=adaltas,dc=com -w test -bou=kerberos,ou=services,dc=adaltas,dc=com dn"
          #   code: 32
          # , (err) ->
          #   next err, if modified then ctx.OK else ctx.PASS
          next err, modified

    module.exports.push name: 'OpenLDAP Kerberos # Index', callback: (ctx, next) ->
      {suffix} = ctx.config.openldap_server
      ctx.ldap_index
        suffix: suffix
        indexes:
          krbPrincipalName: 'sub,eq'
      , next


## Resources

*   [MIT Kerberos Documentation](http://web.mit.edu/kerberos/krb5-devel/doc/admin/conf_ldap.html)
*   [Another I.T. blog](http://itdavid.blogspot.fr/2012/05/howto-centos-62-kerberos-kdc-with.html)




