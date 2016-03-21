  
# OpenLDAP Server Install

The default ports used by OpenLdap server are 389 and 636.

todo: add migrationtools

    module.exports = header: 'OpenLDAP Server Install', handler: ->
      {openldap_server} = @config

## IPTables

| Service    | Port | Proto     | Parameter       |
|------------|------|-----------|-----------------|
| slapd      | 389  | tcp/ldap  | -               |
| slapd      | 636  | tcp/ldaps | -               |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 389, protocol: 'tcp', state: 'NEW', comment: "LDAP (non-secured)" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 636, protocol: 'tcp', state: 'NEW', comment: "LDAP (secured)" }
        ]
        if: @config.iptables.action is 'start'

## Packages

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

      @call header: 'Logging', handler: (options) ->
        options.log 'Check rsyslog dependency'
        @service
          name: 'rsyslog'
        options.log 'Declare local4 in rsyslog configuration'
        @write
          destination: '/etc/rsyslog.conf'
          match: /^local4.*/mg
          replace: 'local4.*                                                /var/log/slapd.log'
          append: 'RULES'
        options.log 'Restart rsyslog service'
        @service
          name: 'rsyslog'
          action: 'restart'
          if: -> @status -1
        @write
          destination: openldap_server.config_file
          match: /^olcLogLevel:.*$/mg
          replace: "olcLogLevel: #{openldap_server.log_level}"
          before: 'olcRootDN'

###
Borrowed from
http://docs.adaptivecomputing.com/viewpoint/hpc/Content/topics/1-setup/installSetup/settingUpOpenLDAPOnCentos6.htm
Interesting posts also include
http://itdavid.blogspot.ca/2012/05/howto-centos-6.html
http://www.6tech.org/2013/01/ldap-server-and-centos-6-3/
###

      @call header: 'Config Access', timeout: -1, handler: (options) ->
        @call (_, callback) ->
          return callback null, false if openldap_server.config_slappasswd
          options.log "Extract password from #{openldap_server.config_file}"
          @fs.readFile openldap_server.config_file, 'ascii', (err, content) ->
            return callback err if err
            if match = /^olcRootPW: {SSHA}(.*)$/m.exec content
              if check_password openldap_server.config_password, match[1]
              then callback null, false
              else callback null, true # Password has changed
            else # First installation, password not yet defined
              callback null, true
        @execute
          cmd: "slappasswd -s #{openldap_server.config_password}"
          if: -> @status -1
        , (err, executed, stdout) ->
          openldap_server.config_slappasswd = stdout.trim() if not err and executed
        @call (_, callback) ->
          options.log 'Database config: root DN & PW'
          write = [match: /^olcRootDN:.*$/m, replace: "olcRootDN: #{openldap_server.config_dn}"]
          if openldap_server.config_slappasswd
            write.push
              match: /^olcRootPW:.*$/m
              replace: "olcRootPW: #{openldap_server.config_slappasswd}"
              append: 'olcRootDN'
          @write
            destination: openldap_server.config_file
            write: write
          @service
            srv_name: 'slapd'
            action: 'restart'
            if: -> @status -1
          @then callback

## DB monitor root DN

      @write
        header: 'DB monitor root DN'
        destination: openldap_server.monitor_file
        match: /^(.*)dc=my-domain,dc=com(.*)$/m
        replace: "$1#{openldap_server.suffix}$2"

## DB bdb

      @call header: 'DB bdb', timeout: -1, handler: (options) ->
        @call (_, callback) ->
          return callback null, false if openldap_server.root_slappasswd
          options.log "Extract password from #{openldap_server.bdb_file}"
          @fs.readFile openldap_server.bdb_file, 'ascii', (err, content) ->
            return callback err if err
            if match = /^olcRootPW: {SSHA}(.*)$/m.exec content
              if check_password openldap_server.root_password, match[1]
              then callback null, false
              else callback null, true # Password has changed
            else # First installation, password not yet defined
              callback null, true
        @execute
          cmd: "slappasswd -s #{openldap_server.root_password}"
          if: -> @status -1
        , (err, executed, stdout) ->
          openldap_server.root_slappasswd = stdout.trim() if not err and executed
        @call (_, callback) ->
          options.log 'Database bdb: root DN, root PW, password protection'
          write = [
            {match: /^(.*)dc=my-domain,dc=com(.*)$/m, replace: "$1#{openldap_server.suffix}$2"}
            {match: /^olcRootDN:.*$/m, replace: "olcRootDN: #{openldap_server.root_dn}"}
          ]
          if openldap_server.root_slappasswd
            write.push
              match: /^olcRootPW:.*$/m
              replace: "olcRootPW: #{openldap_server.root_slappasswd}"
              append: 'olcRootDN'
          @write
            destination: openldap_server.bdb_file
            write: write
          @service
            srv_name: 'slapd'
            action: 'restart'
            if: -> @status -1
          @then callback
    
      [_, suffix_k, suffix_v] = /(\w+)=([^,]+)/.exec openldap_server.suffix
      @execute
        header: 'Users and Groups'
        cmd: """
        ldapadd -c -H ldapi:/// -D #{openldap_server.root_dn} -w #{openldap_server.root_password} <<-EOF
        dn: #{openldap_server.suffix}
        #{suffix_k}: #{suffix_v}
        objectClass: top
        objectClass: domain

        dn: #{openldap_server.users_dn}
        ou: Users
        objectClass: top
        objectClass: organizationalUnit
        description: Central location for UNIX users

        dn: #{openldap_server.groups_dn}
        ou: Groups
        objectClass: top
        objectClass: organizationalUnit
        description: Central location for UNIX groups
        EOF
        """
        code_skipped: 68

## Sudo Schema

      @call header: 'SUDO schema', timeout: -1, handler: ->
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
        @download
          source: "#{__dirname}/resources/ldap.schema"
          destination: '/tmp/ldap.schema'
          mode: 0o0640
          unless: -> @status -1
        @ldap_schema
          name: 'sudo'
          schema: '/tmp/ldap.schema'
          binddn: openldap_server.config_dn
          passwd: openldap_server.config_password
          uri: true
## Delete ldif data

      @call header: 'Delete ldif data', handler: ->
        for path in openldap_server.ldapdelete
          destination = "/tmp/ryba_#{Date.now()}"
          @upload
            source: path
            destination: destination
            mode: 0o0640
          @execute
            cmd: "ldapdelete -c -H ldapi:/// -f #{destination} -D #{openldap_server.root_dn} -w #{openldap_server.root_password}"
            code_skipped: 32
          @remove
            destination: destination

## Add ldif data

      @call header: 'Add ldif data', timeout: 100000, handler: ->
        status = false
        for path in openldap_server.ldapadd
          destination = "/tmp/ryba_#{Date.now()}"
          @upload
            source: path
            destination: destination
            shy: true
          @execute
            cmd: "ldapadd -c -H ldapi:/// -D #{openldap_server.root_dn} -w #{openldap_server.root_password} -f #{destination}"
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

    check_password = (password, shahash) ->
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
