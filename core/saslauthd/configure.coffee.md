
# SASLAuthd Configure

## Default Configuration

```json
{ "saslauthd": {
  "check": {},
  "conf": {},
  "conf_file": "/etc/saslauthd.conf",
  "sysconfig": {
    "SOCKETDIR": "/run/saslauthd",
    "MECH": "ldap",
    "FLAGS": "-O /etc/saslauthd.conf"
  }
} }
```

## AD Exemple

```json
{ "saslauthd": {
  "check": {
    "username": "myself",
    "password": "secret"
  },
  "conf": {
    "ldap_servers": "ldap://ryba.io",
    "ldap_search_base": "dc=ryba,dc=io",
    "ldap_filter": "cn=%u",
    "ldap_bind_dn": "cn=sasladm,ou=users,dc=ryba,dc=io",
    "ldap_password": "secret"
  }
} }
```

    module.exports = ->
      saslauthd = @config.saslauthd ?= {}

## Environnment

      saslauthd.conf_file ?= '/etc/saslauthd.conf'

## Identities

      # Group
      saslauthd.group = name: saslauthd.group if typeof saslauthd.group is 'string'
      saslauthd.group ?= {}
      saslauthd.group.name ?= 'saslauth'
      saslauthd.group.system ?= true
      # User
      saslauthd.user = name: saslauthd.user if typeof saslauthd.user is 'string'
      saslauthd.user ?= {}
      saslauthd.user.name ?= 'saslauth'
      saslauthd.user.system ?= true
      saslauthd.user.gid = 'saslauth'
      saslauthd.user.shell = false
      saslauthd.user.comment ?= 'Saslauthd User'
      saslauthd.user.home = '/run/saslauthd'

## System

The system configuration is written in "/run/saslauthd" and doesnt require any
modification.

      saslauthd.sysconfig ?= {}
      saslauthd.sysconfig = merge {}, saslauthd.sysconfig,
        'SOCKETDIR': '/run/saslauthd'
        'MECH': 'ldap'
        'FLAGS': "-O #{saslauthd.conf_file}"

## Configuration

The configuration is written by default in "/etc/saslauthd.conf" and must be 
entirely defined by the end user.

      saslauthd.conf ?= {}
      throw Error "Required Property: \"conf.ldap_servers\"" unless saslauthd.conf.ldap_servers
      throw Error "Required Property: \"conf.ldap_search_base\"" unless saslauthd.conf.ldap_search_base?
      throw Error "Required Property: \"conf.ldap_bind_dn\"" unless saslauthd.conf.ldap_bind_dn?
      throw Error "Required Property: \"conf.ldap_password\"" unless saslauthd.conf.ldap_password?

## Check

Use a provided username and password to validate the connection, not required.

      saslauthd.check ?= {}
      throw Error "Required Property: \"check.password\"" if saslauthd.check.username and not saslauthd.check.password

## Dependencies

    {merge} = require 'nikita/lib/misc'
