
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

    export default (service) ->
      options = service.options

## Validation

      # Todo: Generate '*_slappasswd' with command `slappasswd -s $password`, but only the first time, we
      # need a mechanism to store configuration properties before.
      throw new Error "Missing \"options.suffix\" property" unless options.suffix
      throw new Error "Missing \"options.root_password\" property" unless options.root_password
      # throw new Error "Missing \"options.root_slappasswd\" property" unless options.root_slappasswd
      throw new Error "Missing \"options.config_dn\" property" unless options.config_dn
      throw new Error "Missing \"options.config_password\" property" unless options.config_password

## Ennvironment

      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.fqdn = service.node.fqdn

## Identities

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'ldap'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'ldap'
      options.user.system ?= true
      options.user.gid = 'ldap'
      options.user.shell = false
      options.user.comment ?= 'LDAP User'
      options.user.home = '/var/lib/ldap'

## Configuration
      
      options.root_dn ?= "cn=Manager,#{options.suffix}"
      options.log_level ?= 256
      options.users_dn ?= "ou=users,#{options.suffix}"
      options.groups_dn ?= "ou=groups,#{options.suffix}"
      options.config_file ?= '/etc/openldap/slapd.d/cn=config/olcDatabase={0}config.ldif'
      options.monitor_file ?= '/etc/openldap/slapd.d/cn=config/olcDatabase={1}monitor.ldif'

## ACL

      throw Error 'Missing required "options.users_dn" property' unless options.users_dn
      throw Error 'Missing required "options.groups_dn" property' unless options.groups_dn
      # options.proxy_user ?= {}
      # options.proxy_user.dn ?= "cn=nssproxy,#{options.users_dn}"
      # options.proxy_user.uid ?= 'nssproxy'
      # options.proxy_user.gecos ?= 'Network Service Switch Proxy User'
      # options.proxy_user.objectClass ?= ['top', 'account', 'posixAccount', 'shadowAccount']
      # options.proxy_user.userPassword ?= 'test'
      # options.proxy_user.shadowLastChange ?= '15140'
      # options.proxy_user.shadowMin ?= '0'
      # options.proxy_user.shadowMax ?= '99999'
      # options.proxy_user.shadowWarning ?= '7'
      # options.proxy_user.loginShell ?= '/bin/false'
      # options.proxy_user.uidNumber ?= '801'
      # options.proxy_user.gidNumber ?= '801'
      # options.proxy_user.homeDirectory ?= '/home/nssproxy'
      # options.proxy_group ?= {}
      # options.proxy_group.dn ?= "cn=nssproxy,#{options.groups_dn}"
      # options.proxy_group.objectClass ?= ['top', 'posixGroup']
      # options.proxy_group.gidNumber ?= '801'
      # options.proxy_group.description ?= 'Network Service Switch Proxy'

## Backend

Select the backend for Openldap. It was originally bdb (Barkeley's DB), and moved to hdb.
In Centos/RHEL it's by default hdb. However since openldap 2.4 the recommend backend is
mdb (backend running inside slapd), which does provide the same functionalities than hdb
but with better performances.

Ryb does install hdb/bdb by default, but administrators can choose mdb.
      
      options.backend ?= 'hdb'
      throw Error "Unsupported slapd backend #{options.backend}" unless options.backend in ['hdb','mdb']
      if options.backend is 'mdb'
        options.db_dir ?= "#{options.user.home}/mdb-db"
        options.db_max_size ?= '1073741824'# 1 Gb

## SSL/TLS

      options.tls ?= false
      unless options.tls
        options.port ?= 389
        options.uri ?= "ldap://#{service.node.fqdn}:#{options.port}"
      else
        throw Error 'TLS mode requires "tls_cert_file"' unless options.tls_cert_file
        throw Error 'TLS mode requires "tls_key_file"' unless options.tls_key_file
        options.port ?= 636
        options.uri ?= "ldaps://#{service.node.fqdn}:#{options.port}"

## Slapd

      options.urls ?= [ 'ldapi:///','ldap:///' ]
      options.urls.push 'ldaps:///' if options.tls and options.urls.indexOf('ldaps:///') is -1

## High Availability (HA)

      options.server_ids = {}
      for openldap_srv, i in service.deps.openldap_server.sort( (srv) -> srv.node.fqdn )
        options.server_ids[openldap_srv.node.fqdn] ?= "#{i+1}"
        if openldap_srv.node.fqdn isnt service.node.fqdn
          options.remote_provider = unless openldap_srv.options.tls
          then "ldap://#{openldap_srv.node.fqdn}:#{openldap_srv.options.port or 389}"
          else "ldaps://#{openldap_srv.node.fqdn}:#{openldap_srv.options.port or 636}"

## SASL

      options.saslauthd = service.deps.saslauthd
      
## Entries

Provision users and groups

      options.ldapadd ?= []
      options.ldapdelete ?= []
      options.entries ?= {}
      options.entries.groups ?= {}
      for name, group of options.entries.groups
        continue unless group
        group = options.entries.groups[name] = misc.merge {},
        group = misc.merge {},
          dn: "cn=#{name},#{options.groups_dn}"
          objectClass: [ 'top', 'posixGroup' ]
          memberUid: []
        , group
        throw Error "Required Entry: gidNumber" unless group.gidNumber
      options.entries.users ?= {}
      for name, user of options.entries.users
        continue unless user
        user = options.entries.users[name] = misc.merge {},
          dn: "cn=#{name},#{options.users_dn}"
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
      options.krb5 ?= {}
      options.krb5.kerberos_dn ?= "cn=kerberos,#{options.suffix}"
      throw Error "attribute 'ou' not allowed" unless options.krb5.kerberos_dn.indexOf('ou=') is -1
      # Configure openldap_server_krb5
      # {admin_group, users_dn, groups_dn, admin_user} = options.krb5
      # User for kdc
      # Example: "dn: cn=krbadmin,ou=groups,dc=adaltas,dc=com"
      options.krb5.kdc_user ?= {}
      options.krb5.kdc_user = misc.merge {},
        dn: "cn=krbadmin,#{options.users_dn}"
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
      , options.krb5.kdc_user
      # User for krbadmin
      # Example: "dn: cn=krbadmin,ou=groups,dc=adaltas,dc=com"
      options.krb5.krbadmin_user ?= {}
      options.krb5.krbadmin_user = misc.merge {},
        dn: "cn=krbadmin,#{options.users_dn}"
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
      , options.krb5.krbadmin_user
      # Group for krbadmin
      # Example: "dn: cn=krbadmin,ou=groups,dc=adaltas,dc=com"
      options.krb5.krbadmin_group ?= {}
      options.krb5.krbadmin_group = misc.merge {},
        dn: "cn=krbadmin,#{options.groups_dn}"
        # cn: 'krbadmin'
        objectClass: [ 'top', 'posixGroup' ]
        gidNumber: '800'
        description: 'Kerberos administrator\'s group.'
      , options.krb5.krbadmin_group

## Dependencies

    misc = require '@nikitajs/core/lib/misc'
