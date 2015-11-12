  
# OpenLDAP Server Install

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/yum'
    exports.push 'masson/core/iptables'
    # exports.push require('./index').configure

The default ports used by OpenLdap server are 389 and 636.

todo: add migrationtools


## IPTables

| Service    | Port | Proto     | Parameter       |
|------------|------|-----------|-----------------|
| slapd      | 389  | tcp/ldap  | -               |
| slapd      | 636  | tcp/ldaps | -               |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    exports.push name: 'OpenLDAP Server # IPTables', handler: ->
      {etc_krb5_conf, kdc_conf} = @config.krb5
      rules = []
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 389, protocol: 'tcp', state: 'NEW', comment: "LDAP (non-secured)" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 636, protocol: 'tcp', state: 'NEW', comment: "LDAP (secured)" }
        ]
        if: @config.iptables.action is 'start'

    exports.push name: 'OpenLDAP Server # Install', timeout: -1, handler: ->
      @service
        name: 'openldap-servers'
        chk_name: 'slapd'
        startup: true
        action: 'start'
      @service
        name: 'openldap-clients'
      @service
        name: 'migrationtools'

## Logging

http://joshitech.blogspot.fr/2009/09/how-to-enabled-logging-in-openldap.html

    exports.push name: 'OpenLDAP Server # Logging', handler: ->
      {config_dn, config_password, config_file, log_level} = @config.openldap_server
      @log 'Check rsyslog dependency'
      @service
        name: 'rsyslog'
      @log? 'Declare local4 in rsyslog configuration'
      @write
        destination: '/etc/rsyslog.conf'
        match: /^local4.*/mg
        replace: 'local4.*                                                /var/log/slapd.log'
        append: 'RULES'
      @log? 'Restart rsyslog service'
      @service
        name: 'rsyslog'
        action: 'restart'
        if: -> @status -1
      @write
        destination: config_file
        match: /^olcLogLevel:.*$/mg
        replace: "olcLogLevel: #{log_level}"
        before: 'olcRootDN'

###
Borrowed from
http://docs.adaptivecomputing.com/viewpoint/hpc/Content/topics/1-setup/installSetup/settingUpOpenLDAPOnCentos6.htm
Interesting posts also include
http://itdavid.blogspot.ca/2012/05/howto-centos-6.html
http://www.6tech.org/2013/01/ldap-server-and-centos-6-3/
###

    exports.push name: 'OpenLDAP Server # Config Access', timeout: -1, handler: ->
      {config_file, config_dn, config_password, config_slappasswd} = @config.openldap_server
      @call (_, callback) ->
        return callback null, false if config_slappasswd
        @log? "Extract password from #{config_file}"
        @fs.readFile config_file, 'ascii', (err, content) ->
          return callback err if err
          if match = /^olcRootPW: {SSHA}(.*)$/m.exec content
            if check_password config_password, match[1]
            then callback null, false
            else callback null, true # Password has changed
          else # First installation, password not yet defined
            callback null, true
      @execute
        cmd: "slappasswd -s #{config_password}"
        if: -> @status -1
      , (err, executed, stdout) ->
        config_slappasswd = stdout.trim() if not err and executed
      @call (_, callback) ->
        @log? 'Database config: root DN & PW'
        write = [match: /^olcRootDN:.*$/m, replace: "olcRootDN: #{config_dn}"]
        if config_slappasswd
          write.push
            match: /^olcRootPW:.*$/m
            replace: "olcRootPW: #{config_slappasswd}"
            append: 'olcRootDN'
        @write
          destination: config_file
          write: write
        @service
          srv_name: 'slapd'
          action: 'restart'
          if: -> @status -1
        @then callback

    exports.push name: 'OpenLDAP Server # DB monitor', timeout: -1, handler: ->
      {suffix, monitor_file} = @config.openldap_server
      @log? 'Database monitor: root DN'
      @write
        destination: monitor_file
        match: /^(.*)dc=my-domain,dc=com(.*)$/m
        replace: "$1#{suffix}$2"

    exports.push name: 'OpenLDAP Server # DB bdb', timeout: -1, handler: ->
      {suffix, bdb_file, root_dn, root_password, root_slappasswd} = @config.openldap_server
      @call (_, callback) ->
        return callback null, false if root_slappasswd
        @log? "Extract password from #{bdb_file}"
        @fs.readFile bdb_file, 'ascii', (err, content) ->
          return callback err if err
          if match = /^olcRootPW: {SSHA}(.*)$/m.exec content
            if check_password root_password, match[1]
            then callback null, false
            else callback null, true # Password has changed
          else # First installation, password not yet defined
            callback null, true
      @execute
        cmd: "slappasswd -s #{root_password}"
        if: -> @status -1
      , (err, executed, stdout) ->
        root_slappasswd = stdout.trim() if not err and executed
      @call (_, callback) ->
        @log? 'Database bdb: root DN, root PW, password protection'
        write = [
          {match: /^(.*)dc=my-domain,dc=com(.*)$/m, replace: "$1#{suffix}$2"}
          {match: /^olcRootDN:.*$/m, replace: "olcRootDN: #{root_dn}"}
        ]
        if root_slappasswd
          write.push
            match: /^olcRootPW:.*$/m
            replace: "olcRootPW: #{root_slappasswd}"
            append: 'olcRootDN'
        @write
          destination: bdb_file
          write: write
        @service
          srv_name: 'slapd'
          action: 'restart'
          if: -> @status -1
        @then callback
    
    exports.push name: 'OpenLDAP Server # Users and Groups', timeout: -1, handler: ->
      {root_dn, root_password, suffix, users_dn, groups_dn} = @config.openldap_server
      [_, suffix_k, suffix_v] = /(\w+)=([^,]+)/.exec suffix
      @execute
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

    exports.push name: 'OpenLDAP Server # SUDO schema', timeout: -1, handler: ->
      {config_dn, config_password} = @config.openldap_server
      @service
        name: 'sudo'
      schema = null
      @execute
        cmd: """
        schema=`rpm -ql sudo | grep -i schema.openldap`
        if [ ! -f $schema ]; then exit 2; fi
        echo $schema
        """
        code_skipped: 2
      , (err, installed, stdout) ->
        schema = stdout.trim() if installed
      @upload
        source: "#{__dirname}/../files/ldap.schema"
        destination: '/tmp/ldap.schema'
        mode: 0o0640
        unless: -> @status -1
      , (err, uploaded) ->
        schema = '/tmp/ldap.schema' if not err and uploaded
      @call ->
        @ldap_schema
          name: 'sudo'
          schema: schema
          binddn: config_dn
          passwd: config_password
          uri: true

    exports.push name: 'OpenLDAP Server # Delete ldif data', handler: ->
      {root_dn, root_password, ldapdelete} = @config.openldap_server
      for path in ldapdelete
        destination = "/tmp/ryba_#{Date.now()}"
        @upload
          source: path
          destination: destination
          mode: 0o0640
        @execute
          cmd: "ldapdelete -c -H ldapi:/// -f #{destination} -D #{root_dn} -w #{root_password}"
          code_skipped: 32
        # , (err, executed, stdout, stderr) ->
        #   return if err
        #   # modified += 1 if stdout.match(/Delete /g).length
        @remove
          destination: destination

    exports.push name: 'OpenLDAP Server # Add ldif data', timeout: 100000, handler: ->
      {root_dn, root_password, ldapadd} = @config.openldap_server
      status = false
      for path in ldapadd
        destination = "/tmp/ryba_#{Date.now()}"
        @upload
          source: path
          destination: destination
          shy: true
        @execute
          cmd: "ldapadd -c -H ldapi:/// -D #{root_dn} -w #{root_password} -f #{destination}"
          code_skipped: 68
          shy: true
        , (err, executed, stdout, stderr) ->
          return if err
          status = true if stdout.match(/Already exists/g)?.length isnt stdout.match(/adding new entry/g).length
        @remove
          destination: destination
          shy: true
      @call (_, callback) ->
        callback null, status

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

## Useful commands

```bash
# Search from local:
ldapsearch -LLLY EXTERNAL -H ldapi:/// -b cn=schema,cn=config dn

# Search from remote:
ldapsearch -x -LLL -H ldap://master3.hadoop:389 -D cn=Manager,dc=ryba -w test -b "dc=ryba" "objectClass=*" 
ldapsearch -H ldaps://master3.hadoop:636 -x -D cn=Manager,dc=ryba -w test -b dc=ryba
ldapsearch -D cn=admin,cn=config -w test -d 1 -b "cn=config"
ldapsearch -D cn=Manager,dc=ryba -w test -b "dc=ryba"
ldapsearch -ZZ -d 5 -D cn=Manager,dc=ryba -w test -b "dc=ryba"

# Check configuration with debug information:
slaptest -v -d5 -u

# Change user password:
ldappasswd -xZWD cn=Manager,dc=ryba -S cn=wdavidw,ou=users,dc=ryba
```

Enable ldapi:// access to root on our ldap tree
  vi /etc/openldap/slapd.d/cn=config/olcDatabase={2}bdb.ldif
  # Add new olcAccess rule
  > olcAccess: {0}to *  by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=externa
  > l,cn=auth" manage  by * none
  ldapsearch -LLLY EXTERNAL -H ldapi:/// -b dc=ryba

Resources:

*   [How to fix "ldif_read_file: checksum error"](http://injustfiveminutes.com/2014/10/28/how-to-fix-ldif_read_file-checksum-error/)
*   [script with just about everything](http://serverfault.com/questions/323497/how-do-i-configure-ldap-on-centos-6-for-user-authentication-in-the-most-secure-a)
