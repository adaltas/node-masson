
## Kerberos Server Install

Install the MIT Kerberos server with an OpenLDAP Back-End.

Usefull server commands:
*   Backup the db: `kdb5_util dump /path/to/dumpfile`
*   Initialize realm: `kdb5_ldap_util -D "cn=Manager,dc=adaltas,dc=com" -w test create -subtrees "ou=kerberos,ou=services,dc=adaltas,dc=com" -r ADALTAS.COM -s -P test`
*   Load the db: `kdb5_util load -update /path/to/dumpfile`
*   Stash password: `kdb5_ldap_util -D "cn=Manager,dc=adaltas,dc=com" -w test stashsrvpw -f /etc/krb5.d/stash.keyfile cn=krbadmin,ou=users,dc=adaltas,dc=com`

Resources:
*   [Kerberos with LDAP backend on centos](http://itdavid.blogspot.fr/2012/05/howto-centos-62-kerberos-kdc-with.html)
*   [Propagation](http://www-old.grantcohoe.com/guides/services/krb5-kdc)
*   [Replication](http://tldp.org/HOWTO/Kerberos-Infrastructure-HOWTO/server-replication.html)
*   [Kerberos with LDAP backend on ubuntu](http://labs.opinsys.com/blog/2010/02/05/setting-up-openldap-kerberos-on-ubuntu-10-04-lucid/)
*   [On Load Balancers and Kerberos](https://ssimo.org/blog/id_019.html)

    safe_etc_krb5_conf = require('.').safe_etc_krb5_conf

    module.exports = header: 'Krb5 Server Install', handler: ->
      {kdc_conf} = @config.krb5

## Wait
  
      @call once: true, 'masson/core/openldap_client/wait'
      
## IPTables

| Service    | Port | Proto | Parameter                            |
|------------|------|-------|--------------------------------------|
| kadmin     | 749  | tcp   | `kdc_conf.kdcdefaults.kadmind_port`  |
| kadmin     | 88   | upd   | `kdc_conf.kdcdefaults.kdc_ports`     |
| krb5kdc    | 88   | tcp   | `kdc_conf.kdcdefaults.kdc_tcp_ports` |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

      rules = []
      add_default_kadmind_port = false
      add_default_kdc_ports = false
      add_default_kdc_tcp_ports = false
      for realm, config of kdc_conf.realms
        if config.kadmind_port
          rules.push chain: 'INPUT', jump: 'ACCEPT', dport: config.kadmind_port, protocol: 'tcp', state: 'NEW', comment: "Kerberos administration server (kadmind daemon)"
        else add_default_kadmind_port = true
        if config.kdc_ports
          for port in config.kdc_ports.split /\s,/
            rules.push chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'udp', state: 'NEW', comment: "Kerberos Authentication Service and Key Distribution Center (krb5kdc daemon)"
        else add_default_kdc_ports = true
        if config.kdc_tcp_ports
          kdc_tcp_ports = true
          for port in config.kdc_ports.split /\s,/
            rules.push chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "Kerberos Authentication Service and Key Distribution Center (krb5kdc daemon)"
        else add_default_kdc_tcp_ports = true
      if add_default_kadmind_port
        port = kdc_conf.kdcdefaults.kadmind_port or '749'
        rules.push chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "Kerberos administration server (kadmind daemon)"
      if add_default_kdc_ports
        for port in (kdc_conf.kdcdefaults.kdc_ports or '88').split /\s,/
          rules.push chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'udp', state: 'NEW', comment: "Kerberos Authentication Service and Key Distribution Center (krb5kdc daemon)"
      if add_default_kdc_tcp_ports
        for port in (kdc_conf.kdcdefaults.kdc_tcp_ports or '88').split /\s,/
          rules.push chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "Kerberos Authentication Service and Key Distribution Center (krb5kdc daemon)"
      @iptables
        header: 'IPTables'
        rules: rules
        if: @config.iptables.action is 'start'

## Package

      @service
        name: 'krb5-pkinit-openssl'
      @service
        name: 'krb5-server-ldap'
        startup: true
        chk_name: 'krb5kdc'
      @service
        name: 'krb5-server-ldap'
        startup: true
        chk_name: 'kadmin'
      @service
        name: 'krb5-workstation'

## Configuration

The following files are updated:   
*   "/etc/krb5.conf" client configuration   
*   "/var/kerberos/krb5kdc/kadm5.acl" acl definition   
*   "/var/kerberos/krb5kdc/kdc.conf" kdc server configuration
*   "/etc/sysconfig/kadmin" kadmin default realm
*   "/etc/sysconfig/krb5kdc" kdc default realm

      @call header: 'Configuration', handler: ->
        {realm, etc_krb5_conf, kdc_conf} = @config.krb5
        any_realm = Object.keys(kdc_conf.realms)[0]
        @write_ini
          content: safe_etc_krb5_conf etc_krb5_conf
          destination: '/etc/krb5.conf'
          stringify: misc.ini.stringify_square_then_curly
          backup: true
        @write 
          write: for realm of etc_krb5_conf.realms
            match: ///^\*/\w+@#{misc.regexp.escape realm}\s+\*///mg
            replace: "*/admin@#{realm}     *"
            append: true
          destination: '/var/kerberos/krb5kdc/kadm5.acl'
          backup: true
        @write_ini
          content: safe_etc_krb5_conf kdc_conf
          destination: '/var/kerberos/krb5kdc/kdc.conf'
          stringify: misc.ini.stringify_square_then_curly
          backup: true
        @write
          destination: '/etc/sysconfig/kadmin'
          match: /^KRB5REALM=.*$/mg
          replace: "KRB5REALM=#{any_realm}"
          backup: true
        @write
          destination: '/etc/sysconfig/krb5kdc'
          match: /^KRB5REALM=.*$/mg
          replace: "KRB5REALM=#{any_realm}"
          backup: true
        @service
          srv_name: 'krb5kdc'
          action: 'restart'
          if: -> @status()
        @service
          srv_name: 'kadmin'
          action: 'restart'
          if: -> @status()

      @call header: 'LDAP Insert Entries', timeout: -1, handler: ->
        {kdc_conf} = @config.krb5
        for realm, config of kdc_conf.realms
          continue unless config.database_module
          {kdc_master_key, ldap_kerberos_container_dn, manager_dn, manager_password, ldap_servers} = kdc_conf.dbmodules[config.database_module]
          ldap_server = ldap_servers.split(' ')[0]
          @wait_execute 
            cmd: """
            ldapsearch -x -LLL \
              -H #{ldap_server} -D \"#{manager_dn}\" -w #{manager_password} \
              -b \"#{ldap_kerberos_container_dn}\"
            """
            code_skipped: 32
          @execute 
            cmd: """
            ldapsearch -x \
            -H #{ldap_server} -D \"#{manager_dn}\" -w #{manager_password} \
            -b \"cn=#{realm},#{ldap_kerberos_container_dn}\"
            """
            code_skipped: 32
          # Note, kdb5_ldap_util is using /etc/krb5.conf (server version)
          @execute
            cmd: """
            kdb5_ldap_util \
            -D \"#{manager_dn}\" -w #{manager_password} \
            create -subtrees \"#{ldap_kerberos_container_dn}\" -r #{realm} -s -P #{kdc_master_key}
            """
            unless: -> @status -1

      @call header: 'LDAP Stash password', timeout: 5*60*1000, handler: (options) ->
        {kdc_conf} = @config.krb5
        # modified = false
        for name, dbmodule of kdc_conf.dbmodules then do(name, dbmodule) =>
        # each kdc_conf.dbmodules
        # .run (name, dbmodule, next) ->
          {kdc_master_key, manager_dn, manager_password, ldap_service_password_file, ldap_kadmind_dn} = dbmodule
          options.log "Stash key file is: #{dbmodule.ldap_service_password_file}"
          keyfileContent = null
          @call (_, callback) ->
            options.log 'Read current keyfile if it exists'
            @fs.readFile "#{ldap_service_password_file}", 'utf8', (err, content) ->
              return callback null, true if err and err.code is 'ENOENT'
              return callback err if err
              keyfileContent = content
              callback null, false
          @mkdir
            destination: path.dirname(ldap_service_password_file)
            if: -> @status -1
          @call (_, callback) ->
            options.log 'Stash password into local file for kadmin dn'
            @options.ssh.shell (err, stream) =>
              return callback err if err
              cmd = "kdb5_ldap_util -D \"#{manager_dn}\" -w #{manager_password} stashsrvpw -f #{ldap_service_password_file} #{ldap_kadmind_dn}"
              options.log "Run #{cmd}"
              reentered = done = false
              stream.write "#{cmd}\n"
              stream.on 'data', (data, stderr) =>
                # options.log[if stderr then 'err' else 'out'].write data
                data = data.toString()
                if /Password for/.test data
                  stream.write "#{kdc_master_key}\n"
                else if /Re-enter password for/.test data
                  stream.write "#{kdc_master_key}\n\n"
                  reentered = true
                else if reentered and not done
                  done = true
                  stream.end 'exit\n'
              stream.on 'exit', ->
                callback()
          @call (_, callback) ->
            return callback null, true  unless keyfileContent
            @fs.readFile "#{ldap_service_password_file}", 'utf8', (err, content) ->
              return callback err if err
              modified = if keyfileContent is content then false else true
              callback null, keyfileContent isnt content

      @call header: 'Krb5 Server # Log', timeout: 100000, handler: ->
        @touch
          destination: '/var/log/krb5kdc.log'
        @touch
          destination: '/var/log/kadmind.log'
        @write
          destination: '/etc/rsyslog.conf'
          write: [
            match: /.*krb5kdc.*/mg
            replace: 'if $programname == \'krb5kdc\' then /var/log/krb5kdc.log'
            append: '### RULES ###'
          ,
            match: /.*kadmind.*/mg
            replace: 'if $programname == \'kadmind\' then /var/log/kadmind.log'
            append: '### RULES ###'
          ]
        @service_start
          name: 'krb5kdc'
          if: -> @status -1
        @service_start
          name: 'kadmin'
          if: -> @status -2
        @service
          srv_name: 'rsyslog'
          action: 'restart'
          if: -> @status -3

      @call header: 'Krb5 Server # Admin principal', timeout: -1, handler: ->
        {etc_krb5_conf, kdc_conf} = @config.krb5
        for realm, config of etc_krb5_conf.realms
          continue unless kdc_conf.realms[realm]?.database_module
          # We dont provide an "kadmin_server". Instead, we need
          # to use "kadmin.local" because the principal used
          # to login with "kadmin" isnt created yet
          @krb5_addprinc
            realm: realm
            principal: config.kadmin_principal
            password: config.kadmin_password
        # modified = false
        # each(etc_krb5_conf.realms)
        # .on 'item', (realm, config, next) ->
        #   {kadmin_principal, kadmin_password} = config
        #   return next() unless kdc_conf.realms[realm]?.database_module
        #   options.log "Create principal #{kadmin_principal}"
        #   @krb5_addprinc
        #     # We dont provide an "kadmin_server". Instead, we need
        #     # to use "kadmin.local" because the principal used
        #     # to login with "kadmin" isnt created yet
        #     realm: realm
        #     principal: kadmin_principal
        #     password: kadmin_password
        #   , (err, created) ->
        #     return next err if err
        #     modified = true if created
        #     next()
        # .on 'both', (err) ->
        #   next err, modified

    # TODO: no time to work on this, the idea is to modified kadmin startup
    # script to handle multiple kadmin server. Note, for `killproc` to stop
    # all instances, it seems that we need to set multiple pid files, here
    # a exemple: `/usr/sbin/kadmind -r USERS.ADALTAS.COM -P /var/run/kadmind1.pid`
    # exports.push name: 'Krb5 Server # Startup', timeout: 100000, handler: ->
    #   {kdc_conf} = @config.krb5
    #   write = []
    #   write.push match: /^(\s+)(daemon\s+.*)/mg, replace: "$1#$2"
    #   for realm, _ of kdc_conf
    #     replace: "        daemon ${kadmind} -r"
    #     append: /\s+#daemon\s+.*/
    #   @write
    #     destination: '/etc/init.d/kadmin'
    #     write: write
    #   , next

      # exports.push header: 'Krb5 Server # Start', timeout: 100000, handler: ->
      #   @service_start
      #     name: 'krb5kdc'
      #   @service_start
      #     name: 'kadmin'

## Dependencies

    path = require 'path'
    misc = require 'mecano/lib/misc'

## Notes

Renewable tickets is per default disallowed in the most linux distributions. This can be done per:

```bash
kadmin.local: modprinc -maxrenewlife 7day krbtgt/YOUR_REALM
kadmin.local: modprinc -maxrenewlife 7day +allow_renewable hue/FQRN
```
