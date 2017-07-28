
# OpenLDAP Server Configure

The property "openldap_server.config_slappasswd" may be generated with the command `slappasswd`
and should correspond to "openldap_server.config_password".

## Provision users and groups

```json
{ "openldap_server": { "entries": {
  "groups": {
    "my_group": {
      "gidNumber": "1234",
      "memberUid": ["5678"]
    },
    "my_user": {
      "gidNumber": "5678"
    }
  },
  "users": {
    "my_user": {
      "uidNumber": "5678",
      "gidNumber": "5678",
      "userPassword": "my secret"
    }
  }
} } }
```

    module.exports = ->
      # Todo: Generate '*_slappasswd' with command `slappasswd -s $password`, but only the first time, we
      # need a mechanism to store configuration properties before.
      openldap_ctxs = @contexts 'masson/core/openldap_server'
      openldap_server = @config.openldap_server ?= {}
      throw new Error "Missing \"openldap_server.suffix\" property" unless openldap_server.suffix
      throw new Error "Missing \"openldap_server.root_password\" property" unless openldap_server.root_password
      # throw new Error "Missing \"openldap_server.root_slappasswd\" property" unless openldap_server.root_slappasswd
      throw new Error "Missing \"openldap_server.config_dn\" property" unless openldap_server.config_dn
      throw new Error "Missing \"openldap_server.config_password\" property" unless openldap_server.config_password
      # Group
      openldap_server.group = name: openldap_server.group if typeof openldap_server.group is 'string'
      openldap_server.group ?= {}
      openldap_server.group.name ?= 'ldap'
      openldap_server.group.system ?= true
      # User
      openldap_server.user = name: openldap_server.user if typeof openldap_server.user is 'string'
      openldap_server.user ?= {}
      openldap_server.user.name ?= 'ldap'
      openldap_server.user.system ?= true
      openldap_server.user.gid = 'ldap'
      openldap_server.user.shell = false
      openldap_server.user.comment ?= 'LDAP User'
      openldap_server.user.home = '/var/lib/ldap'
      # Configuration
      {suffix} = openldap_server
      openldap_server.root_dn ?= "cn=Manager,#{openldap_server.suffix}"
      openldap_server.log_level ?= 256
      openldap_server.users_dn ?= "ou=users,#{suffix}"
      openldap_server.groups_dn ?= "ou=groups,#{suffix}"
      openldap_server.ldapadd ?= []
      openldap_server.ldapdelete ?= []
      openldap_server.tls ?= false
      openldap_server.config_file ?= '/etc/openldap/slapd.d/cn=config/olcDatabase={0}config.ldif'
      openldap_server.monitor_file ?= '/etc/openldap/slapd.d/cn=config/olcDatabase={1}monitor.ldif'
      if openldap_server.tls
        throw Error 'TLS mode requires "tls_cert_file"' unless openldap_server.tls_cert_file
        throw Error 'TLS mode requires "tls_key_file"' unless openldap_server.tls_key_file
        openldap_server.uri = "ldaps://#{@config.host}"
      else
        openldap_server.uri = "ldap://#{@config.host}"

## ACL

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

## Backend
Select the backend for Openldap. It was originally bdb (Barkeley's DB), and moved to hdb.
In Centos/RHEL it's by default hdb. However since openldap 2.4 the recommend backend is
mdb (backend running inside slapd), which does provide the same functionalities than hdb
but with better performances.

Ryb does install hdb/bdb by default, but administrators can choose mdb.
      
      openldap_server.backend ?= 'hdb'
      throw Error "Unsupported slapd backend #{openldap_server.backend}" unless openldap_server.backend in ['hdb','mdb']
      if openldap_server.backend is 'mdb'
        openldap_server.db_dir ?= "#{openldap_server.user.home}/mdb-db"
        openldap_server.db_max_size ?= '1073741824'# 1 Gb
      
      
## Entries

Provision users and groups

      openldap_server.entries ?= {}
      openldap_server.entries.groups ?= {}
      for name, group of openldap_server.entries.groups
        continue unless group
        group = openldap_server.entries.groups[name] = misc.merge {},
        group = misc.merge {},
          dn: "cn=#{name},#{openldap_server.groups_dn}"
          objectClass: [ 'top', 'posixGroup' ]
          memberUid: []
        , group
        throw Error "Required Entry: gidNumber" unless group.gidNumber
      openldap_server.entries.users ?= {}
      for name, user of openldap_server.entries.users
        continue unless user
        user = openldap_server.entries.users[name] = misc.merge {},
          dn: "cn=#{name},#{openldap_server.users_dn}"
          objectClass: [
            'top', 'inetOrgPerson', 'organizationalPerson',
            'person', 'posixAccount'
          ]
          sn: "#{name}"
          uid: "#{name}"
          homeDirectory: "/home/#{name}"
          loginShell: '/bin/bash'
          # givenName: ''
          # displayname: ''
        , user
        throw Error "Required Entry: uidNumber" unless user.uidNumber
        throw Error "Required Entry: gidNumber" unless user.gidNumber
        throw Error "Required Entry: userPassword" unless user.userPassword

## Kerberos Schema

      # Normalization
      @config.openldap_server_krb5 ?= {}
      {openldap_server, openldap_server_krb5} = @config
      openldap_server_krb5.kerberos_dn ?= "cn=kerberos,#{openldap_server.suffix}"
      throw Error "attribute 'ou' not allowed" unless openldap_server_krb5.kerberos_dn.indexOf('ou=') is -1
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

## Slapd

      openldap_server.urls ?= [ 'ldapi:///','ldap:///' ]
      openldap_server.urls.push 'ldaps:///' if openldap_server.tls and openldap_server.urls.indexOf('ldaps:///') is -1

## High Availability (HA)

      openldap_server.server_ids = {}
      for openldap_ctx, i in openldap_ctxs.sort( (ctx) -> ctx.config.host )
        openldap_server.server_ids[openldap_ctx.config.host] ?= "#{i+1}"
        if openldap_ctx.config.host isnt @config.host
          openldap_server.remote_provider = if openldap_ctx.config.openldap_server.tls
          then "ldaps://#{openldap_ctx.config.host}"
          else "ldap://#{openldap_ctx.config.host}"

## Dependencies

    misc = require 'nikita/lib/misc'
