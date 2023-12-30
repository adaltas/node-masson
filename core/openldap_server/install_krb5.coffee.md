
# OpenLDAP Kerberos

Install the [OpenLDAP backend for the MIT Kerberos server](https://web.mit.edu/kerberos/krb5-latest/doc/admin/conf_ldap.html).

## Configuration

    export default header: 'OpenLDAP Server Krb5', handler: ({options}) ->

## Install schema

Prepare and deploy the kerberos schema. Upon installation, it
is possible to check if the schema is installed by calling
the command `ldapsearch  -D cn=admin,cn=config -w test -b "cn=config"`.

      @call header: 'Schema', handler: ->
        @log message: 'Install schema', level: 'DEBUG'
        @service
          name: 'krb5-server-ldap'
        @log message: 'Get schema location', level: 'DEBUG'
        schema = null
        @system.execute
          cmd: 'rpm -ql krb5-server-ldap | grep kerberos.schema'
        , (err, data) ->
          throw Error 'Kerberos schema not found' if not err and data.stdout is ''
          schema = data.stdout
        @call ->
          @ldap.schema
            name: 'kerberos'
            schema: schema
            binddn: options.config_dn
            passwd: options.config_password
            uri: true

## Insert Container

Create the kerberos entry unit, for example "cn=kerberos,dc=adaltas,dc=com".
Note: In recent version of openldap, dn compose or organizationalUnit (ou) are 
not allowed to be used for krb5 ldap containers.

      @ldap.add
        header: 'Container DN'
        uri: true
        binddn: options.root_dn
        passwd: options.root_password
        entry:
          dn: "#{options.krb5.kerberos_dn}"
          objectClass: ['krbContainer']

## Insert Group

Create the kerberos administrator's group.

      @ldap.add
        header: 'Group DN'
        uri: true
        binddn: options.root_dn
        passwd: options.root_password
        entry: options.krb5.krbadmin_group

# Insert Admin User

Create the kerberos administrator's user.

      @ldap.user
        header: 'User DN'
        uri: true
        binddn: options.root_dn
        passwd: options.root_password
        user: options.krb5.krbadmin_user

## Krb5 User permissions

      @call
        header: 'User permissions'
      , ->
        @ldap.acl
          header: 'Create'
          suffix: options.suffix
          acls: [
            place_before: "dn.subtree=\"#{options.suffix}\""
            to: "dn.subtree=\"#{options.krb5.kerberos_dn}\""
            by: [
              "dn.exact=\"#{options.krb5.krbadmin_user.dn}\" write"
              "dn.base=\"gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth\" read"
              "* none"
            ]
          # ,
          #   to: "dn.subtree=\"#{options.suffix}\""
          #   by: [
          #     "dn.exact=\"#{options.krb5.krbadmin_user.dn}\" write"
          #   ]
          ]
        @system.execute
          header: 'Check'
          if: -> @status -1
          cmd: "ldapsearch -H ldapi:// -x -D #{options.krb5.krbadmin_user.dn} -w #{options.krb5.krbadmin_user.userPassword} -b #{options.krb5.kerberos_dn}"

## Krb5 Index

      @ldap.index
        header: 'Krb5 Index'
        suffix: options.suffix
        indexes:
          krbPrincipalName: 'sub,eq'

## Dependencies

    ssha = require 'ssha'
    {check_password} = require './index'

## Resources

*   [MIT Kerberos Documentation](http://web.mit.edu/kerberos/krb5-devel/doc/admin/conf_ldap.html)
*   [Another I.T. blog](http://itdavid.blogspot.fr/2012/05/howto-centos-62-kerberos-kdc-with.html)
