
# Kerberos Client

Kerberos is a network authentication protocol. It is designed 
to provide strong authentication for client/server applications 
by using secret-key cryptography.

This module install the client tools written by the [Massachusetts 
Institute of Technology](http://web.mit.edu).

## Install

The package "krb5-workstation" is installed.

    module.exports = header: 'Krb5 Client', handler: ->
      @service
        header: 'Package'
        timeout: -1
        name: 'krb5-workstation'

## Configure

Modify the Kerberos configuration file in "/etc/krb5.conf". Note, 
this action wont be run if the server host a Kerberos server. 
This is to avoid any conflict where both modules would try to write 
their own configuration one. We give the priority to the server module 
which create a Kerberos file with complementary information.

      @write_ini
        header: 'Configuration'
        timeout: -1
        # Kerberos config is also managed by the kerberos server action.
        unless: -> @has_module 'masson/core/krb5_server'
        content: safe_etc_krb5_conf @config.krb5.etc_krb5_conf
        destination: '/etc/krb5.conf'
        stringify: misc.ini.stringify_square_then_curly
        backup: true

## Host Principal

Create a user principal for this host. The principal is named like 
"host/{hostname}@{realm}". Only apply to the default realm 
("krb5.etc\_krb5\_conf.libdefaults.default_realm") unless the property
"etc_krb5_conf[realm].create\_hosts" is set.

      @call header: 'Host Principal', timeout: -1, handler: ->
        {etc_krb5_conf} = @config.krb5
        default_realm = etc_krb5_conf.libdefaults.default_realm
        modified = false
        for realm, config of etc_krb5_conf.realms
          # Note:
          # The doc above say "apply if default realm unless create_hosts"
          # but this isnt what we do bellow
          # As a consequence, we never enter here, which might be acceptable
          # but doc and code need to be aligned.
          continue if default_realm isnt realm or not config.create_hosts
          @wait_execute
            cmd: misc.kadmin
              realm: realm
              kadmin_principal: config.kadmin_principal
              kadmin_password: config.kadmin_password
              kadmin_server: config.admin_server
            , 'listprincs'
          @krb5_addprinc
            principal: "host/#{@config.host}@#{realm}"
            randkey: true
            kadmin_principal: config.kadmin_principal
            kadmin_password: config.kadmin_password
            kadmin_server: config.admin_server

## principals

Populate the Kerberos database with new principals. The "wait" property is
set to 10s because multiple instance of this handler may try to create the same
principals and generate concurrency errors.

      @call header: 'Principals', wait: 10000, handler: ->
        {etc_krb5_conf} = @config.krb5
        for realm, config of etc_krb5_conf.realms
          continue unless config.principals
          for principal in config.principals  
            @krb5_addprinc misc.merge
              kadmin_principal: config.kadmin_principal
              kadmin_password: config.kadmin_password
              kadmin_server: config.admin_server
            , principal

## Configure SSHD

Updated the "/etc/ssh/sshd\_config" file with properties provided by the "krb5.sshd" 
configuration object. By default, we set the following properties to "yes": "ChallengeResponseAuthentication",
"KerberosAuthentication", "KerberosOrLocalPasswd", "KerberosTicketCleanup", "GSSAPIAuthentication", 
"GSSAPICleanupCredentials". The "sshd" service will be restarted if a change to the configuration is detected.

      @call
        header: 'Configure SSHD'
        if: -> @config.krb5.sshd
        handler: ->
          {sshd} = @config.krb5
          @write
            write: for k, v of sshd
              match: new RegExp "^#{k}.*$", 'mg'
              replace: "#{k} #{v}"
              append: true
            destination: '/etc/ssh/sshd_config'
          @service
            srv_name: 'sshd'
            action: 'restart'
            if: -> @status -1

## Module Dependencies

    misc = require 'mecano/lib/misc'
    {safe_etc_krb5_conf} = require './index'

## Useful Client Commands

*   List all the current principals in the realm: `getprincs`
*   Login to a local kadmin: `kadmin.local`
*   Login to a remote kadmin: `kadmin -p wdavidw/admin@ADALTAS.COM -s krb5.hadoop`
*   Print details on a principal: `getprinc host/hadoop1.hadoop@ADALTAS.COM`
*   Examine the content of the /etc/krb5.keytab: `klist -etk /etc/krb5.keytab`
*   Destroy our own tickets: `kdestroy`
*   Get a user ticket: `kinit -p wdavidw@ADALTAS.COM`
*   Confirm that we do indeed have the new ticket: `klist`
*   Check krb5kdc is listening: `netstat -nap | grep :750` and `netstat -nap | grep :88`

## Todo

*   Enable sshd(8) Kerberos authentication.
*   Enable PAM Kerberos authentication.
*   SASL GSSAPI OpenLDAP authentication.
*   Use SASL GSSAPI Authentication with AutoFS.

## Notes

Kerberos clients require connectivity to the KDC's TCP ports 88 and 749.
