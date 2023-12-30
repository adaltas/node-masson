
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

    export default (service) ->
      options = service.options

## Environment

      options.conf_file ?= '/etc/saslauthd.conf'

## Identities

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'saslauth'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'saslauth'
      options.user.system ?= true
      options.user.gid = 'saslauth'
      options.user.shell = false
      options.user.comment ?= 'options User'
      options.user.home = '/run/saslauthd'

## System

The system configuration is written in "/run/saslauthd" and doesnt require any
modification.

      options.sysconfig ?= {}
      options.sysconfig = merge options.sysconfig,
        'SOCKETDIR': '/run/saslauthd'
        'MECH': 'ldap'
        'FLAGS': "-O #{options.conf_file}"

## Configuration

The configuration is written by default in "/etc/saslauthd.conf" and must be 
entirely defined by the end user.

      options.conf ?= {}
      if options.sysconfig['MECH'] is 'ldap'
        # http://www.openldap.org/doc/admin24/security.html#Pass-Through%20authentication
        throw Error "Required Property: \"conf.ldap_servers\"" unless options.conf.ldap_servers
        throw Error "Required Property: \"conf.ldap_search_base\"" unless options.conf.ldap_search_base?
        throw Error "Required Property: \"conf.ldap_bind_dn\"" unless options.conf.ldap_bind_dn?
        throw Error "Required Property: \"conf.ldap_password\"" unless options.conf.ldap_password?

## Check

Use a provided username and password to validate the connection, not required.

      options.check ?= {}
      throw Error "Required Property: \"check.password\"" if options.check.username and not options.check.password

## Dependencies

    {merge} = require 'mixme'
