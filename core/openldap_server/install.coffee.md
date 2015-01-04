  
# OpenLDAP Server Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/iptables'
    module.exports.push require('./index').configure

The default ports used by OpenLdap server are 389 and 636.

todo: add migrationtools


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
      , next

    module.exports.push name: 'OpenLDAP Server # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        name: 'openldap-servers'
        chk_name: 'slapd'
        startup: true
        action: 'start'
      ,
        name: 'openldap-clients'
      ,
        name: 'migrationtools'
      ], next

###
Borrowed from
http://docs.adaptivecomputing.com/viewpoint/hpc/Content/topics/1-setup/installSetup/settingUpOpenLDAPOnCentos6.htm
Interesting posts also include
http://itdavid.blogspot.ca/2012/05/howto-centos-6.html
http://www.6tech.org/2013/01/ldap-server-and-centos-6-3/
###

    module.exports.push name: 'OpenLDAP Server # DB config', timeout: -1, callback: (ctx, next) ->
      {config_file, config_dn, config_password, config_slappasswd} = ctx.config.openldap_server
      do_compare_rootpw = ->
        return do_write() if config_slappasswd
        ctx.log "Extract password from #{config_file}"
        ctx.fs.readFile config_file, 'ascii', (err, content) ->
          return next err if err
          if match = /^olcRootPW: {SSHA}(.*)$/m.exec content
            if check_password config_password, match[1]
            then do_write()
            else do_create_rootpw() # Password has changed
          else # First installation, password not yet defined
            do_create_rootpw()
      do_create_rootpw = ->
        ctx.execute
          cmd: "slappasswd -s #{config_password}"
        , (err, executed, stdout) ->
          return next err if err
          config_slappasswd = stdout.trim()
          do_write()
      do_write = ->
        ctx.log 'Database config: root DN & PW'
        write = [match: /^olcRootDN:.*$/mg, replace: "olcRootDN: #{config_dn}"]
        if config_slappasswd
          write.push
            match: /^olcRootPW:.*$/mg
            replace: "olcRootPW: #{config_slappasswd}"
            append: 'olcRootDN'
        ctx.write
          destination: config_file
          write: write
        , (err, written) ->
          return next err, false if err or not written
          ctx.service
            srv_name: 'slapd'
            action: 'restart'
          , next
      do_compare_rootpw()

    module.exports.push name: 'OpenLDAP Server # DB monitor', timeout: -1, callback: (ctx, next) ->
      {suffix, monitor_file} = ctx.config.openldap_server
      ctx.log 'Database monitor: root DN'
      ctx.write
        destination: monitor_file
        match: /^(.*)dc=my-domain,dc=com(.*)$/mg
        replace: "$1#{suffix}$2"
      , next

    module.exports.push name: 'OpenLDAP Server # DB bdb', timeout: -1, callback: (ctx, next) ->
      {suffix, bdb_file, root_dn, root_password, root_slappasswd} = ctx.config.openldap_server
      modified = 0
      do_compare_rootpw = ->
        return do_write() if root_slappasswd
        ctx.log "Extract password from #{bdb_file}"
        ctx.fs.readFile bdb_file, 'ascii', (err, content) ->
          return next err if err
          if match = /^olcRootPW: {SSHA}(.*)$/m.exec content
            if check_password root_password, match[1]
            then do_write()
            else do_create_rootpw() # Password has changed
          else # First installation, password not yet defined
            do_create_rootpw()
      do_create_rootpw = ->
        ctx.execute
          cmd: "slappasswd -s #{root_password}"
        , (err, executed, stdout) ->
          return next err if err
          root_slappasswd = stdout.trim()
          do_write()
      do_write = ->
        ctx.log 'Database bdb: root DN, root PW, password protection'
        write = [
          {match: /^(.*)dc=my-domain,dc=com(.*)$/mg, replace: "$1#{suffix}$2"}
          {match: /^olcRootDN:.*$/mg, replace: "olcRootDN: #{root_dn}"}
        ]
        if root_slappasswd
          write.push
            match: /^olcRootPW:.*$/mg
            replace: "olcRootPW: #{root_slappasswd}"
            append: 'olcRootDN'
        ctx.write
          destination: bdb_file
          write: write
        , (err, written) ->
          return next err, false if err or not written
          ctx.service
            srv_name: 'slapd'
            action: 'restart'
          , next
      do_compare_rootpw()

## Logging

http://joshitech.blogspot.fr/2009/09/how-to-enabled-logging-in-openldap.html

    module.exports.push name: 'OpenLDAP Server # Logging', callback: (ctx, next) ->
      {config_dn, config_password, config_file, log_level} = ctx.config.openldap_server
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
        ctx.write
          destination: config_file
          match: /^olcLogLevel:.*$/mg
          replace: "olcLogLevel: #{log_level}"
          before: 'olcRootDN'
        , (err, written) ->
          modified = true if written
          finish err
      finish = (err) ->
        next err, modified
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
      , next

    module.exports.push name: 'OpenLDAP Server # SUDO schema', timeout: -1, callback: (ctx, next) ->
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
          cmd: """
          schema=`rpm -ql sudo | grep -i schema.openldap`
          if [ ! -f $schema ]; then exit 2; fi
          echo $schema
          """
          code_skipped: 2
        , (err, installed, schema) ->
          return next err if err
          # return next Error 'Sudo schema not found' if schema is ''
          return do_register schema.trim() if installed
          ctx.upload
            source: "#{__dirname}/../files/ldap.schema"
            destination: '/tmp/ldap.schema'
          , (err, uploaded) ->
            return next err if err
            do_register '/tmp/ldap.schema'
      do_register = (schema) ->
        ctx.ldap_schema
          name: 'sudo'
          schema: schema
          binddn: config_dn
          passwd: config_password
          uri: true
          log: ctx.log
          ssh: ctx.ssh
        , next
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
        next err, modified

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
            console.log stdout
            console.log '-------------'
            console.log stdout.match(/Already exists/g)?.length
            console.log stdout.match(/adding new entry/g).length
            modified += 1 if stdout.match(/Already exists/g)?.length isnt stdout.match(/adding new entry/g).length
            ctx.log "Clean temp file: #{destination}"
            ctx.remove
              destination: destination
            , (err, removed) ->
              next err
      .on 'both', (err) ->
        next err, modified

## Exported functions

    module.exports.check_password = check_password = (password, shahash) ->
      buf = new Buffer shahash, 'base64'
      hash = buf.slice 0, 20
      salt = buf.slice 20, 24
      return hash.toString('base64') is crypto
      .createHash('sha1')
      .update(password)
      .update(salt)
      .digest('base64')

## Module Dependencies

    crypto = require 'crypto'
    each = require 'each'

## Useful commands

```bash
# Search from local:
ldapsearch -LLLY EXTERNAL -H ldapi:/// -b cn=schema,cn=config dn

# Search from remote:
ldapsearch -x -LLL -H ldap://master3.hadoop:389 -D cn=Manager,dc=adaltas,dc=com -w test -b "dc=adaltas,dc=com" "objectClass=*" 
ldapsearch -H ldaps://master3.hadoop:636 -x -D cn=Manager,dc=adaltas,dc=com -w test -b dc=adaltas,dc=com
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



