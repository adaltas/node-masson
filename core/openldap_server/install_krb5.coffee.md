
# OpenLDAP Kerberos

## Configuration

    module.exports = header: 'OpenLDAP Server Krb5', handler: ->
      {kerberos_dn, krbadmin_user, krbadmin_group} = @config.openldap_server_krb5
      {openldap_server} = @config

## Install schema

Prepare and deploy the kerberos schema. Upon installation, it
is possible to check if the schema is installed by calling
the command `ldapsearch  -D cn=admin,cn=config -w test -b "cn=config"`.

      @call header: 'Schema', timeout: -1, handler: (options) ->
        {openldap_server} = @config
        options.log message: 'Install schema', level: 'DEBUG'
        @service
          name: 'krb5-server-ldap'
        options.log message: 'Get schema location', level: 'DEBUG'
        schema = null
        @system.execute
          cmd: 'rpm -ql krb5-server-ldap | grep kerberos.schema'
        , (err, executed, stdout) ->
          throw Error 'Kerberos schema not found' if not err and stdout is ''
          schema = stdout
        @call ->
          @ldap_schema
            name: 'kerberos'
            schema: schema
            binddn: openldap_server.config_dn
            passwd: openldap_server.config_password

## Insert Container

Create the kerberos entry unit, for example "cn=kerberos,dc=adaltas,dc=com".
Note: In recent version of openldap, dn compose or organizationalUnit (ou) are 
not allowed to be used for krb5 ldap containers.

      @ldap_add
        header: 'Container DN'
        uri: openldap_server.uri,
        binddn: openldap_server.root_dn,
        passwd: openldap_server.root_password,
        entry: 
          dn: "#{kerberos_dn}"
          objectClass: ['krbContainer']

## Insert Group

Create the kerberos administrator's group.

      @ldap_add
        header: 'Group DN'
        uri: openldap_server.uri,
        binddn: openldap_server.root_dn,
        passwd: openldap_server.root_password,
        entry: krbadmin_group

# Insert Admin User

Create the kerberos administrator's user.

      @ldap.user
        header: 'User DN'
        uri: openldap_server.uri,
        binddn: openldap_server.root_dn,
        passwd: openldap_server.root_password,
        user: krbadmin_user

## Krb5 User permissions

      @call
        header: 'User permissions'
        handler: (options) ->
          @ldap_acl
            suffix: openldap_server.suffix
            acls: [
              place_before: "dn.subtree=\"#{openldap_server.suffix}\""
              to: "dn.subtree=\"#{kerberos_dn}\""
              by: [
                "dn.exact=\"#{krbadmin_user.dn}\" write"
                "dn.base=\"gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth\" read"
                "* none"
              ]
            ,
              to: "dn.subtree=\"#{openldap_server.suffix}\""
              by: [
                "dn.exact=\"#{krbadmin_user.dn}\" write"
              ]
            ]
          options.log message: "Check it returns the entire #{kerberos_dn} subtree", level: 'DEBUG'
          @system.execute
            cmd: "ldapsearch -H #{openldap_server.uri} -x -D #{krbadmin_user.dn} -w #{krbadmin_user.userPassword} -b #{kerberos_dn}"

## Krb5 Index

      @ldap.index
        header: 'Krb5 Index'
        suffix: openldap_server.suffix
        indexes:
          krbPrincipalName: 'sub,eq'

## Dependencies

    ssha = require 'ssha'
    {check_password} = require './index'

## Resources

*   [MIT Kerberos Documentation](http://web.mit.edu/kerberos/krb5-devel/doc/admin/conf_ldap.html)
*   [Another I.T. blog](http://itdavid.blogspot.fr/2012/05/howto-centos-62-kerberos-kdc-with.html)
