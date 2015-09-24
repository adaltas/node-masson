
# OpenLDAP Kerberos

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Configuration

We make sure to set "ldap_admin" which isn't present in
force mode.

    module.exports.configure = (ctx) ->
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

    exports.push name: 'OpenLDAP Server # Kerberos Install schema', timeout: -1, handler: ->
      {config_dn, config_password} = @config.openldap_server
      @log? 'Install schema'
      @service
        name: 'krb5-server-ldap'
      @log? 'Get schema location'
      schema = null
      @execute
        cmd: 'rpm -ql krb5-server-ldap | grep kerberos.schema'
      , (err, executed, stdout) ->
        throw Error 'Kerberos schema not found' if not err and stdout is ''
        schema = stdout
      @call ->
        @ldap_schema
          name: 'kerberos'
          schema: schema
          binddn: config_dn
          passwd: config_password

## Insert Container

Create the kerberos organisational unit, for example 
"ou=kerberos,dc=adaltas,dc=com".

    exports.push name: 'OpenLDAP Server # Kerberos Insert Container', handler: ->
      {kerberos_dn, krbadmin_user} = @config.openldap_server_krb5
      {openldap_server} = @config
      @ldap_add 
        uri: openldap_server.uri,
        binddn: openldap_server.root_dn,
        passwd: openldap_server.root_password,
        entry: 
          dn: "#{kerberos_dn}"
          objectClass: ['top', 'organizationalUnit']
          description: 'Kerberos OU to store Kerberos principals.'

## Insert Group

Create the kerberos administrator's group.

    exports.push name: 'OpenLDAP Server # Kerberos Insert Group', handler: ->
      {krbadmin_group} = @config.openldap_server_krb5
      {openldap_server} = @config
      @ldap_add
        uri: openldap_server.uri,
        binddn: openldap_server.root_dn,
        passwd: openldap_server.root_password,
        entry: krbadmin_group

# Insert Admin User

Create the kerberos administrator's user.

    exports.push name: 'OpenLDAP Server # Kerberos Insert User', handler: ->
      {krbadmin_user} = @config.openldap_server_krb5
      {openldap_server} = @config
      @ldap_user
        uri: openldap_server.uri,
        binddn: openldap_server.root_dn,
        passwd: openldap_server.root_password,
        user: krbadmin_user

    exports.push name: 'OpenLDAP Server # Kerberos User permissions', handler: ->
      # We used: http://itdavid.blogspot.fr/2012/05/howto-centos-62-kerberos-kdc-with.html
      # But this is also interesting: http://web.mit.edu/kerberos/krb5-current/doc/admin/conf_ldap.html
      {kerberos_dn, krbadmin_user} = @config.openldap_server_krb5
      {uri, suffix} = @config.openldap_server
      @ldap_acl
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
      @log? "Check it returns the entire #{kerberos_dn} subtree"
      @execute
        cmd: "ldapsearch -H #{uri} -x -D #{krbadmin_user.dn} -w #{krbadmin_user.userPassword} -b #{kerberos_dn}"

    exports.push name: 'OpenLDAP Server # Kerberos Index', handler: ->
      {suffix} = @config.openldap_server
      @ldap_index
        suffix: suffix
        indexes:
          krbPrincipalName: 'sub,eq'

## Module Dependencies

    ssha = require 'ssha'
    {check_password} = require './index'
    misc = require 'mecano/lib/misc'

## Resources

*   [MIT Kerberos Documentation](http://web.mit.edu/kerberos/krb5-devel/doc/admin/conf_ldap.html)
*   [Another I.T. blog](http://itdavid.blogspot.fr/2012/05/howto-centos-62-kerberos-kdc-with.html)
