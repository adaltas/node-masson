
# OpenLDAP Kerberos

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Configuration

We make sure to set "ldap_admin" which isn't present in
force mode.

    exports.push module.exports.configure = (ctx) ->
      require('./index').configure ctx
      # Normalization
      ctx.config.openldap_server_krb5 ?= {}
      {openldap_server, openldap_server_krb5} = ctx.config
      openldap_server_krb5.kerberos_dn ?= "ou=kerberos,#{openldap_server.suffix}"
      # Configure openldap_server_krb5
      # {admin_group, users_dn, groups_dn, admin_user} = openldap_server_krb5
      # User for kdc
      # Example: "dn: cn=krbadmin,ou=groups,dc=adaltas,dc=com"
      openldap_server_krb5.kdc_user ?= {}
      openldap_server_krb5.kdc_user = misc.merge {},
        dn: "cn=krbadmin,#{openldap_server.users_dn}"
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
        userPassword: 'test'
      , openldap_server_krb5.kdc_user
      # User for krbadmin
      # Example: "dn: cn=krbadmin,ou=groups,dc=adaltas,dc=com"
      openldap_server_krb5.krbadmin_user ?= {}
      openldap_server_krb5.krbadmin_user = misc.merge {},
        dn: "cn=krbadmin,#{openldap_server.users_dn}"
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
        userPassword: 'test'
      , openldap_server_krb5.krbadmin_user
      # Group for krbadmin
      # Example: "dn: cn=krbadmin,ou=groups,dc=adaltas,dc=com"
      openldap_server_krb5.krbadmin_group ?= {}
      openldap_server_krb5.krbadmin_group = misc.merge {},
        dn: "cn=krbadmin,#{openldap_server.groups_dn}"
        # cn: 'krbadmin'
        objectClass: [ 'top', 'posixGroup' ]
        gidNumber: '800'
        description: 'Kerberos administrator\'s group.'
      , openldap_server_krb5.krbadmin_group

## Install schema

Prepare and deploy the kerberos schema. Upon installation, it
is possible to check if the schema is installed by calling
the command `ldapsearch  -D cn=admin,cn=config -w test -b "cn=config"`.

    exports.push name: 'OpenLDAP Kerberos # Install schema', timeout: -1, handler: (ctx, next) ->
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

    exports.push name: 'OpenLDAP Kerberos # Insert Container', handler: (ctx, next) ->
      {kerberos_dn, krbadmin_user} = ctx.config.openldap_server_krb5
      {url, root_dn, root_password} = ctx.config.openldap_server
      ctx.ldap_add 
        url: url,
        binddn: root_dn,
        passwd: root_password,
        entry: 
          dn: "#{kerberos_dn}"
          objectClass: ['top', 'organizationalUnit']
          description: 'Kerberos OU to store Kerberos principals.'
      , next

## Insert Group

Create the kerberos administrator's group.

    exports.push name: 'OpenLDAP Kerberos # Insert Group', handler: (ctx, next) ->
      {krbadmin_group} = ctx.config.openldap_server_krb5
      {url, root_dn, root_password} = ctx.config.openldap_server
      ctx.ldap_add
        url: url,
        binddn: root_dn,
        passwd: root_password,
        entry: krbadmin_group
      , next

# Insert Admin User

Create the kerberos administrator's user.

    exports.push name: 'OpenLDAP Kerberos # Insert User', handler: (ctx, next) ->
      {krbadmin_user} = ctx.config.openldap_server_krb5
      {url, root_dn, root_password, users_dn, groups_dn} = ctx.config.openldap_server
      ctx.ldap_user
        url: url,
        binddn: root_dn,
        passwd: root_password,
        user: krbadmin_user
      , next

    exports.push name: 'OpenLDAP Kerberos # User permissions', handler: (ctx, next) ->
      # We used: http://itdavid.blogspot.fr/2012/05/howto-centos-62-kerberos-kdc-with.html
      # But this is also interesting: http://web.mit.edu/kerberos/krb5-current/doc/admin/conf_ldap.html
      {kerberos_dn, krbadmin_user} = ctx.config.openldap_server_krb5
      {suffix} = ctx.config.openldap_server
      ctx.ldap_acl [
        suffix: suffix
        acls: [
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

    exports.push name: 'OpenLDAP Kerberos # Index', handler: (ctx, next) ->
      {suffix} = ctx.config.openldap_server
      ctx.ldap_index
        suffix: suffix
        indexes:
          krbPrincipalName: 'sub,eq'
      , next

## Module Dependencies

    ssha = require 'ssha'
    {check_password} = require './index'
    misc = require 'mecano/lib/misc'

## Resources

*   [MIT Kerberos Documentation](http://web.mit.edu/kerberos/krb5-devel/doc/admin/conf_ldap.html)
*   [Another I.T. blog](http://itdavid.blogspot.fr/2012/05/howto-centos-62-kerberos-kdc-with.html)




