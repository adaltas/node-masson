
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

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/openldap_client'
    exports.push 'masson/core/openldap_client/wait'
    exports.push 'masson/core/iptables'
    exports.push 'masson/core/yum'
    exports.push require('./index').configure
    safe_etc_krb5_conf = require('./index').safe_etc_krb5_conf

## IPTables

| Service    | Port | Proto | Parameter                            |
|------------|------|-------|--------------------------------------|
| kadmin     | 749  | tcp   | `kdc_conf.kdcdefaults.kadmind_port`  |
| kadmin     | 88   | upd   | `kdc_conf.kdcdefaults.kdc_ports`     |
| krb5kdc    | 88   | tcp   | `kdc_conf.kdcdefaults.kdc_tcp_ports` |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    exports.push name: 'Krb5 Server # IPTables', handler: (ctx, next) ->
      {kdc_conf} = ctx.config.krb5
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
      ctx.iptables
        rules: rules
        if: ctx.config.iptables.action is 'start'
      , next

    exports.push name: 'Krb5 Server # LDAP Install', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'krb5-server-ldap'
      , next

    exports.push name: 'Krb5 Server # LDAP Configuration', timeout: 100000, handler: (ctx, next) ->
      {etc_krb5_conf} = ctx.config.krb5
      ctx.ini
        content: safe_etc_krb5_conf etc_krb5_conf
        destination: '/etc/krb5.conf'
        stringify: misc.ini.stringify_square_then_curly
        backup: true
      , next

    exports.push name: 'Krb5 Server # Install', timeout: -1, handler: (ctx, next) ->
      ctx.log 'Install krb5kdc and kadmin services'
      ctx.service [
        name: 'krb5-pkinit-openssl'
      ,
        name: 'krb5-server-ldap'
        startup: true
        chk_name: 'krb5kdc'
      ,
        name: 'krb5-server-ldap'
        startup: true
        chk_name: 'kadmin'
      ,
        name: 'words'
      ,
        name: 'krb5-workstation'
      ], next

    exports.push name: 'Krb5 Server # Configure', timeout: 100000, handler: (ctx, next) ->
      {realm, etc_krb5_conf, kdc_conf} = ctx.config.krb5
      modified = false
      exists = false
      do_exists = ->
        ctx.fs.exists '/etc/krb5.conf', (err, e) ->
          exists = e
          do_krb5()
      do_krb5 = ->
        ctx.ini
          content: safe_etc_krb5_conf etc_krb5_conf
          destination: '/etc/krb5.conf'
          stringify: misc.ini.stringify_square_then_curly
          backup: true
        , (err, written) ->
          return next err if err
          modified = true if written
          do_kadm5()
      do_kadm5 = ->
        # Not sure this is a good idea,
        # we end up with admin user from another realm
        writes = for realm of etc_krb5_conf.realms
          match: ///^\*/\w+@#{misc.regexp.escape realm}\s+\*///mg
          replace: "*/admin@#{realm}     *"
          append: true
        ctx.write 
          write: writes
          destination: '/var/kerberos/krb5kdc/kadm5.acl'
          backup: true
        , (err, written) ->
          return next err if err
          modified = true if written
          do_kdc()
      do_kdc = ->
        ctx.ini
          content: safe_etc_krb5_conf kdc_conf
          destination: '/var/kerberos/krb5kdc/kdc.conf'
          stringify: misc.ini.stringify_square_then_curly
          backup: true
        , (err, written) ->
          return next err if err
          modified = true if written
          do_sysconfig()
      do_sysconfig = ->
        realm = Object.keys(kdc_conf.realms)[0]
        ctx.write [
          destination: '/etc/sysconfig/kadmin'
          match: /^KRB5REALM=.*$/mg
          replace: "KRB5REALM=#{realm}"
          backup: true
        ,
          destination: '/etc/sysconfig/krb5kdc'
          match: /^KRB5REALM=.*$/mg
          replace: "KRB5REALM=#{realm}"
          backup: true
        ], (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = (err) ->
        return next err if err
        return next null, false unless modified
        # The first time, we dont restart because ldap conf is 
        # not there yet
        return next null, true unless exists
        ctx.log '(Re)start krb5kdc and kadmin services'
        ctx.service [
          name: 'krb5-server'
          action: 'restart'
          srv_name: 'krb5kdc'
        ,
          name: 'krb5-server'
          action: 'restart'
          srv_name: 'kadmin'
        ], (err, serviced) ->
          next err, true
      do_exists()

    exports.push name: 'Krb5 Server # LDAP Insert Entries', timeout: -1, handler: (ctx, next) ->
      {kdc_conf} = ctx.config.krb5
      modified = false
      each(kdc_conf.realms)
      .on 'item', (realm, config, next) ->
        return next() unless config.database_module
        {kdc_master_key, ldap_kerberos_container_dn, manager_dn, manager_password, ldap_servers} = kdc_conf.dbmodules[config.database_module]
        ldap_server = ldap_servers.split(' ')[0]
        do_wait = ->
          ctx.waitForExecution 
            cmd: "ldapsearch -x -LLL -H #{ldap_server} -D \"#{manager_dn}\" -w #{manager_password} -b \"#{ldap_kerberos_container_dn}\""
            code_skipped: 32
          , (err) ->
            return next err if err
            do_exists()
        do_exists = ->
          searchbase = "cn=#{realm},#{ldap_kerberos_container_dn}"
          ctx.execute 
            cmd: "ldapsearch -x -H #{ldap_server} -D \"#{manager_dn}\" -w #{manager_password} -b \"#{searchbase}\""
            code_skipped: 32
          , (err, exists) ->
            return next err if err
            if exists then next() else do_subtrees()
        do_subtrees = ->
          # Note, kdb5_ldap_util is using /etc/krb5.conf (server version)
          ctx.execute
            cmd: "kdb5_ldap_util -D \"#{manager_dn}\" -w #{manager_password} create -subtrees \"#{ldap_kerberos_container_dn}\" -r #{realm} -s -P #{kdc_master_key}"
          , (err, executed, stdout, stderr) ->
            return next err if err
            modified = true if executed
            next()
        do_wait()
      .on 'both', (err) ->
        next err, modified

    exports.push name: 'Krb5 Server # LDAP Stash password', handler: (ctx, next) ->
      {kdc_conf} = ctx.config.krb5
      modified = false
      each(kdc_conf.dbmodules)
      .on 'item', (name, dbmodule, next) ->
        {kdc_master_key, manager_dn, manager_password, ldap_service_password_file, ldap_kadmind_dn} = dbmodule
        ctx.log "Stash key file is: #{dbmodule.ldap_service_password_file}"
        keyfileContent = null
        do_read = ->
          ctx.log 'Read current keyfile if it exists'
          ctx.fs.readFile "#{ldap_service_password_file}", 'utf8', (err, content) ->
            return do_mkdir() if err and err.code is 'ENOENT'
            return next err if err
            keyfileContent = content
            do_stash()
        do_mkdir = ->
          ctx.log 'Create directory "/etc/krb5.d"'
          ctx.mkdir path.dirname(ldap_service_password_file), (err, created) ->
            return next err if err
            do_stash()
        do_stash = ->
          ctx.log 'Stash password into local file for kadmin dn'
          ctx.ssh.shell (err, stream) ->
            return next err if err
            cmd = "kdb5_ldap_util -D \"#{manager_dn}\" -w #{manager_password} stashsrvpw -f #{ldap_service_password_file} #{ldap_kadmind_dn}"
            ctx.log "Run #{cmd}"
            reentered = done = false
            stream.write "#{cmd}\n"
            stream.on 'data', (data, stderr) ->
              ctx.log[if stderr then 'err' else 'out'].write data
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
              do_compare()
        do_compare = ->
          unless keyfileContent
            modified = true
            return next()
          ctx.fs.readFile "#{ldap_service_password_file}", 'utf8', (err, content) ->
            return next err if err
            modified = if keyfileContent is content then false else true
            next()
        do_read()
      .on 'both', (err) ->
        next err, modified

    exports.push name: 'Krb5 Server # Log', timeout: 100000, handler: (ctx, next) ->
      modified = false
      touch = ->
        ctx.log 'Touch "/etc/logrotate.d/krb5kdc" and "/etc/logrotate.d/kadmind"'
        ctx.write [
          content: ''
          destination: '/var/log/krb5kdc.log'
          not_if_exists: true
        ,
          content: ''
          destination: '/var/log/kadmind.log'
          not_if_exists: true
        ], (err, written) ->
          return done err if err
          modified = true if written
          rsyslog()
      rsyslog = ->
        ctx.log 'Update /etc/rsyslog.conf'
        ctx.write
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
        , (err, written) ->
          return done err if err
          modified = true if written
          if written then restart() else done()
      restart = ->
        ctx.log 'Restart krb5kdc and kadmin'
        ctx.service [
          action: 'start'
          srv_name: 'krb5kdc'
        ,
          action: 'start'
          srv_name: 'kadmin'
        ], (err, restarted) ->
          return done err if err
          ctx.log 'Restart rsyslog'
          ctx.service
            srv_name: 'rsyslog'
            action: 'restart'
          , (err, restarted) ->
            done err
      done = (err) ->
        next err, modified
      touch()

    exports.push name: 'Krb5 Server # Admin principal', timeout: -1, handler: (ctx, next) ->
      {etc_krb5_conf, kdc_conf} = ctx.config.krb5
      modified = false
      each(etc_krb5_conf.realms)
      .on 'item', (realm, config, next) ->
        {kadmin_principal, kadmin_password} = config
        return next() unless kdc_conf.realms[realm]?.database_module
        ctx.log "Create principal #{kadmin_principal}"
        ctx.krb5_addprinc
          # We dont provide an "kadmin_server". Instead, we need
          # to use "kadmin.local" because the principal used
          # to login with "kadmin" isnt created yet
          realm: realm
          principal: kadmin_principal
          password: kadmin_password
        , (err, created) ->
          return next err if err
          modified = true if created
          next()
      .on 'both', (err) ->
        next err, modified

    # TODO: no time to work on this, the idea is to modified kadmin startup
    # script to handle multiple kadmin server. Note, for `killproc` to stop
    # all instances, it seems that we need to set multiple pid files, here
    # a exemple: `/usr/sbin/kadmind -r USERS.ADALTAS.COM -P /var/run/kadmind1.pid`
    # exports.push name: 'Krb5 Server # Startup', timeout: 100000, handler: (ctx, next) ->
    #   {kdc_conf} = ctx.config.krb5
    #   write = []
    #   write.push match: /^(\s+)(daemon\s+.*)/mg, replace: "$1#$2"
    #   for realm, _ of kdc_conf
    #     replace: "        daemon ${kadmind} -r"
    #     append: /\s+#daemon\s+.*/
    #   ctx.write
    #     destination: '/etc/init.d/kadmin'
    #     write: write
    #   , next

    exports.push name: 'Krb5 Server # Start', timeout: 100000, handler: (ctx, next) ->
      ctx.service [
        srv_name: 'krb5kdc'
        action: 'start'
      ,
        srv_name: 'kadmin'
        action: 'start'
      ], next

## Module Dependencies

    path = require 'path'
    each = require 'each'
    misc = require 'mecano/lib/misc'

## Notes

Renewable tickets is per default disallowed in the most linux distributions. This can be done per:

```bash
kadmin.local: modprinc -maxrenewlife 7day krbtgt/YOUR_REALM
kadmin.local: modprinc -maxrenewlife 7day +allow_renewable hue/FQRN
```





