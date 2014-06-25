---
title: 
layout: module
---

# OpenLDAP

    each = require 'each'
    ldap = require 'ldapjs'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/iptables'

The default ports used by OpenLdap server are 389 and 636.

todo: add migrationtools


Configuration
-------------

The property "openldap_server.config_slappasswd" may be generated with the command `slappasswd` 
and should correspond to "openldap_server.config_password".

    module.exports.push module.exports.configure = (ctx) ->
      require('./iptables').configure ctx
      # Todo: Generate '*_slappasswd' with command `slappasswd`, but only the first time, we
      # need a mechanism to store configuration properties before.
      ctx.config.openldap_server ?= {}
      throw new Error "Missing \"openldap_server.suffix\" property" unless ctx.config.openldap_server.suffix
      throw new Error "Missing \"openldap_server.root_password\" property" unless ctx.config.openldap_server.root_password
      throw new Error "Missing \"openldap_server.root_slappasswd\" property" unless ctx.config.openldap_server.root_slappasswd
      throw new Error "Missing \"openldap_server.config_dn\" property" unless ctx.config.openldap_server.config_dn
      throw new Error "Missing \"openldap_server.config_password\" property" unless ctx.config.openldap_server.config_password
      throw new Error "Missing \"openldap_server.config_slappasswd\" property" unless ctx.config.openldap_server.config_slappasswd
      {suffix} = ctx.config.openldap_server
      ctx.config.openldap_server.root_dn ?= "cn=Manager,#{ctx.config.openldap_server.suffix}"
      ctx.config.openldap_server.log_level ?= 256
      ctx.config.openldap_server.users_dn ?= "ou=users,#{suffix}"
      ctx.config.openldap_server.groups_dn ?= "ou=groups,#{suffix}"
      ctx.config.openldap_server.ldapadd ?= []
      ctx.config.openldap_server.ldapdelete ?= []
      ctx.config.openldap_server.tls ?= false
      ctx.ldap_add = (ctx, content, callback) ->
        {root_dn, root_password} = ctx.config.openldap_server
        tmp = "/tmp/ldapadd_#{Date.now()}_#{Math.round(Math.random()*1000)/1000}"
        ctx.write
          content: content
          destination: tmp
        , (err, uploaded) ->
          return callback err if err
          ctx.execute
            cmd: "ldapadd -c -H ldapi:/// -D #{root_dn} -w #{root_password} -f #{tmp}"
            code_skipped: 68
          , (err, executed, stdout, stderr) ->
            return callback err if err
            modified = true if stdout.match(/Already exists/g)?.length isnt stdout.match(/adding new entry/g).length
            ctx.remove
              destination: tmp
            , (err, removed) ->
              callback err, modified

## IPTables

| Service    | Port | Proto     | Parameter       |
|------------|------|-----------|-----------------|
| slapd      | 389  | tcp/ldap  | -               |
| slapd      | 636  | tcp/ldaps | -               |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'OpenLDAP Server # IPTables', callback: (ctx, next) ->
      {etc_krb5_conf, kdc_conf} = ctx.config.krb5
      rules = []
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 389, protocol: 'tcp', state: 'NEW', comment: "LDAP (non-secured)" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 636, protocol: 'tcp', state: 'NEW', comment: "LDAP (secured)" }
        ]
        if: ctx.config.iptables.action is 'start'
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'OpenLDAP Server # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        name: 'openldap-servers'
        chk_name: 'slapd'
        startup: true
      ,
        name: 'openldap-clients'
      ,
        name: 'migrationtools'
      ], (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

###
Borrowed from
http://docs.adaptivecomputing.com/viewpoint/hpc/Content/topics/1-setup/installSetup/settingUpOpenLDAPOnCentos6.htm
Interesting posts also include
http://itdavid.blogspot.ca/2012/05/howto-centos-6.html
http://www.6tech.org/2013/01/ldap-server-and-centos-6-3/
###

    module.exports.push name: 'OpenLDAP Server # Configure', timeout: -1, callback: (ctx, next) ->
      {root_dn, root_slappasswd, suffix} = ctx.config.openldap_server
      modified = 0
      bdb = ->
        ctx.log 'Database bdb: root DN, root PW, password protection'
        ctx.write
          destination: '/etc/openldap/slapd.d/cn=config/olcDatabase={2}bdb.ldif'
          write: [
            match: /^(.*)dc=my-domain,dc=com(.*)$/mg
            replace: "$1#{suffix}$2"
          ,
            match: /^olcRootDN.*$/mg
            replace: "olcRootDN: #{root_dn}"
          ,
            match: /^olcRootPW.*$/mg
            replace: "olcRootPW: #{root_slappasswd}"
            append: 'olcRootDN'
          ]
        , (err, written) ->
          return next err if err
          modified += written
          monitor()
      monitor = ->
        ctx.log 'Database monitor: root DN'
        ctx.write
          destination: '/etc/openldap/slapd.d/cn=config/olcDatabase={1}monitor.ldif'
          match: /^(.*)dc=my-domain,dc=com(.*)$/mg
          replace: "$1#{suffix}$2"
        , (err, written) ->
          return next err if err
          modified += written
          config()
      config = ->
        {config_dn, config_slappasswd} = ctx.config.openldap_server
        ctx.log 'Database config: root DN & PW'
        ctx.write
          destination: '/etc/openldap/slapd.d/cn=config/olcDatabase={0}config.ldif'
          write: [
            match: /^olcRootDN.*$/mg
            replace: "olcRootDN: #{config_dn}"
          ,
            match: /^olcRootPW.*$/mg
            replace: "olcRootPW: #{config_slappasswd}"
            append: 'olcRootDN'
          ]
        , (err, written) ->
          return next err if err
          modified += written
          restart()
      restart = ->
        return next null, ctx.PASS unless modified
        ctx.log 'Restart service'
        ctx.service
          name: 'openldap-servers'
          srv_name: 'slapd'
          action: 'restart'
        , (err, restarted) ->
          next err, ctx.OK
      bdb()

## Logging

http://joshitech.blogspot.fr/2009/09/how-to-enabled-logging-in-openldap.html

    module.exports.push name: 'OpenLDAP Server # Logging', callback: (ctx, next) ->
      {config_dn, config_password, log_level} = ctx.config.openldap_server
      modified = false
      rsyslog = ->
        ctx.log 'Check rsyslog dependency'
        ctx.service
          name: 'rsyslog'
        , (err, serviced) ->
          return next err if err
          ctx.log 'Declare local4 in rsyslog configuration'
          ctx.write
            destination: '/etc/rsyslog.conf'
            match: /^local4.*/mg
            replace: 'local4.*                                                /var/log/slapd.log'
            append: 'RULES'
          , (err, written) ->
            return next err if err
            return slapdconf() unless written
            ctx.log 'Restart rsyslog service'
            ctx.service
              name: 'rsyslog'
              action: 'restart'
            , (err, serviced) ->
              modified = true
              slapdconf()
      slapdconf = ->
        # TODO, seems like there is an error if we run this against an 
        # already installed openldap but stop at the time. A possible
        # solution would be to make sure the service is started:
        #
        #     ctx.service 
        #       name: 'openldap-servers'
        #       srv_name: 'slapd'
        #       action: 'start'
        #
        ctx.log 'Open connection'
        client = ldap.createClient url: "ldap://#{ctx.config.host}/"
        ctx.log 'Bind connection'
        client.bind "#{config_dn}", "#{config_password}", (err) ->
          return finish err if err
          ctx.log 'Search attribute olcLogLevel'
          client.search 'cn=config', 
            filter: 'cn=config'
            scope: 'base'
            attributes: ['olcLogLevel']
          , (err, search) ->
            return unbind client, err if err
            olcLogLevel = null
            search.on 'searchEntry', (entry) ->
              ctx.log "Found #{JSON.stringify entry.object}"
              olcLogLevel = entry.object.olcLogLevel
            search.on 'end', ->
              ctx.log "Attribute olcLogLevel is #{JSON.stringify olcLogLevel}"
              return unbind client if "#{olcLogLevel}" is "#{log_level}"
              ctx.log "Modify attribute olcLogLevel to #{JSON.stringify log_level}"
              change = new ldap.Change
                operation: 'replace'
                modification: olcLogLevel: log_level
              client.modify 'cn=config', change, (err) ->
                return unbind client, err if err
                modified = true
                unbind client
      unbind = (client, err) ->
        ctx.log 'Unbind connection'
        client.unbind (e) ->
          return next e if e
          finish err
      finish = (err) ->
        next err, if modified then ctx.OK else ctx.PASS
      rsyslog()

    module.exports.push name: 'OpenLDAP Server # Users and Groups', timeout: -1, callback: (ctx, next) ->
      {root_dn, root_password, suffix, users_dn, groups_dn} = ctx.config.openldap_server
      [_, suffix_k, suffix_v] = /(\w+)=([^,]+)/.exec suffix
      ctx.execute
        cmd: """
        ldapadd -c -H ldapi:/// -D #{root_dn} -w #{root_password} <<-EOF
        dn: #{suffix}
        #{suffix_k}: #{suffix_v}
        objectClass: top
        objectClass: domain

        dn: #{users_dn}
        ou: Users
        objectClass: top
        objectClass: organizationalUnit
        description: Central location for UNIX users

        dn: #{groups_dn}
        ou: Groups
        objectClass: top
        objectClass: organizationalUnit
        description: Central location for UNIX groups
        EOF
        """
        code_skipped: 68
      , (err, executed) ->
        return next err, if executed then ctx.OK else ctx.PASS

    module.exports.push name: 'OpenLDAP Server # SUDO schema', timeout: -1, callback: (ctx, next) ->
      # conf = '/tmp/sudo_schema/schema.conf'
      # ldif = '/tmp/sudo_schema/ldif'
      {config_dn, config_password} = ctx.config.openldap_server
      do_install = ->
        ctx.log 'Install Sudo schema'
        ctx.service
          name: 'sudo'
        , (err, serviced) ->
          return next err if err
          do_locate()
      do_locate = ->
        ctx.log 'Get schema location'
        ctx.execute
          cmd: 'rpm -ql sudo | grep -i schema.openldap'
        , (err, executed, schema) ->
          return next err if err
          return next Error 'Sudo schema not found' if schema is ''
          do_register schema.trim()
      do_register = (schema) ->
        ctx.ldap_schema
          name: 'sudo'
          schema: schema
          binddn: config_dn
          passwd: config_password
          uri: true
          log: ctx.log
          ssh: ctx.ssh
        , (err, registered) ->
          next err, if registered then ctx.OK else ctx.PASS
      do_install()

    module.exports.push name: 'OpenLDAP Server # Delete ldif data', callback: (ctx, next) ->
      {root_dn, root_password, ldapdelete} = ctx.config.openldap_server
      return next() unless ldapdelete.length
      modified = 0
      each(ldapdelete)
      .on 'item', (path, next) ->
        destination = "/tmp/phyla_#{Date.now()}"
        ctx.upload
          source: path
          destination: destination
        , (err, uploaded) ->
          return next err if err
          ctx.log "Delete #{destination}"
          ctx.execute
            cmd: "ldapdelete -c -H ldapi:/// -f #{destination} -D #{root_dn} -w #{root_password}"
            code_skipped: 32
          , (err, executed, stdout, stderr) ->
            return next err if err
            # modified += 1 if stdout.match(/Delete /g).length
            ctx.remove
              destination: destination
            , (err, removed) ->
              next err
      .on 'both', (err) ->
        next err, if modified then ctx.OK else ctx.PASS

    module.exports.push name: 'OpenLDAP Server # Add ldif data', timeout: 100000, callback: (ctx, next) ->
      {root_dn, root_password, ldapadd} = ctx.config.openldap_server
      return next() unless ldapadd.length
      modified = 0
      each(ldapadd)
      .on 'item', (path, next) ->
        destination = "/tmp/phyla_#{Date.now()}"
        ctx.log "Create temp file: #{destination}"
        ctx.upload
          source: path
          destination: destination
        , (err, uploaded) ->
          return next err if err
          ctx.execute
            cmd: "ldapadd -c -H ldapi:/// -D #{root_dn} -w #{root_password} -f #{destination}"
            code_skipped: 68
          , (err, executed, stdout, stderr) ->
            return next err if err
            modified += 1 if stdout.match(/Already exists/g)?.length isnt stdout.match(/adding new entry/g).length
            ctx.log "Clean temp file: #{destination}"
            ctx.remove
              destination: destination
            , (err, removed) ->
              next err
      .on 'both', (err) ->
        next err, if modified then ctx.OK else ctx.PASS

## Useful commands

```bash
# Search from local:
ldapsearch -LLLY EXTERNAL -H ldapi:/// -b cn=schema,cn=config dn

# Search from remote:
ldapsearch -x -LLL -H ldap://openldap.hadoop:389 -D cn=Manager,dc=adaltas,dc=com -w test -b "dc=adaltas,dc=com" "objectClass=*" 
ldapsearch -D cn=admin,cn=config -w test -d 1 -b "cn=config"
ldapsearch -D cn=Manager,dc=adaltas,dc=com -w test -b "dc=adaltas,dc=com"
ldapsearch -ZZ -d 5 -D cn=Manager,dc=adaltas,dc=com -w test -b "dc=adaltas,dc=com"

# Check configuration with debug information:
slaptest -v -d5 -u

# Change user password:
ldappasswd -xZWD cn=Manager,dc=adaltas,dc=com -S cn=wdavidw,ou=users,dc=adaltas,dc=com
```


Enable ldapi:// access to root on our ldap tree
  vi /etc/openldap/slapd.d/cn=config/olcDatabase={2}bdb.ldif
  # Add new olcAccess rule
  > olcAccess: {0}to *  by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=externa
  > l,cn=auth" manage  by * none
  ldapsearch -LLLY EXTERNAL -H ldapi:/// -b dc=adaltas,dc=com

Resources:

  http://serverfault.com/questions/323497/how-do-i-configure-ldap-on-centos-6-for-user-authentication-in-the-most-secure-a
  ... provide a script with just about everything



