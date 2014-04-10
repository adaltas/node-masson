---
title: Kerberos Client
module: masson/core/krb5_client
layout: module
---

# Kerberos Client

Kerberos is a network authentication protocol. It is designed 
to provide strong authentication for client/server applications 
by using secret-key cryptography.

This module install the client tools written by the [Massachusetts 
Institute of Technology](http://web.mit.edu).

    each = require 'each'
    misc = require 'mecano/lib/misc'
    krb5_server = require './krb5_server'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/ssh'
    module.exports.push 'masson/core/ntp'
    module.exports.push 'masson/core/openldap_client'

## Configuration

*   `krb5.kadmin_principal` (string, required)
*   `krb5.kadmin_password` (string, required)
*   `krb5.kadmin_server` (string, required)
*   `krb5.realm` (string, required)
*   `krb5.etc_krb5_conf` (object)
    Object representing the full ini file in "/etc/krb5.conf". It is
    generated by default.
*   `krb5.sshd` (object)
    Properties inserted in the "/etc/ssh/sshd_config" file.

Example:
```json
{
  "krb5": {
    "realm": "ADALTAS.COM",
    "kdc": "krb5.hadoop",
    "kadmin_server": "krb5.hadoop",
    "kadmin_principal": "wdavidw/admin@ADALTAS.COM",
    "kadmin_password": "test"
  }
}
```

    safe_etc_krb5_conf = module.exports.safe_etc_krb5_conf = (etc_krb5_conf) ->
      etc_krb5_conf = krb5_server.safe_etc_krb5_conf etc_krb5_conf
      for realm, config of etc_krb5_conf.realms
        delete config.database_module
      delete etc_krb5_conf.dbmodules
      etc_krb5_conf

    module.exports.push module.exports.configure = (ctx) ->
      require('./krb5_server').configure ctx
      ctx.config.krb5.sshd ?= {}
      # ctx.config.krb5.sshd = misc.merge
      #   #ChallengeResponseAuthentication: 'yes'
      #   #KerberosAuthentication: 'yes'
      #   #KerberosOrLocalPasswd: 'yes'
      #   #KerberosTicketCleanup: 'yes'
      #   #GSSAPIAuthentication: 'yes'
      #   #GSSAPICleanupCredentials: 'yes'
      # , ctx.config.krb5.sshd

## Install

The package "krb5-workstation" is installed.

    module.exports.push name: 'Krb5 client # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service
        name: 'krb5-workstation'
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

## Configure

Modify the Kerberos configuration file in "/etc/krb5.conf". Note, 
this action wont be run if the server host a Kerberos server. 
This is to avoid any conflict where both modules would try to write 
their own configuration one. We give the priority to the server module 
which create a Kerberos file with complementary information.

    module.exports.push name: 'Krb5 client # Configure', timeout: -1, callback: (ctx, next) ->
      # Kerberos config is also managed by the kerberos server action.
      ctx.log 'Check who manage /etc/krb5.conf'
      return next null, ctx.INAPPLICABLE if ctx.has_module 'masson/core/krb5_server'
      {etc_krb5_conf} = ctx.config.krb5
      ctx.log 'Update /etc/krb5.conf'
      ctx.ini
        content: safe_etc_krb5_conf etc_krb5_conf
        destination: '/etc/krb5.conf'
        stringify: misc.ini.stringify_square_then_curly
      , (err, written) ->
        return next err, if written then ctx.OK else ctx.PASS

## Host Principal

Create a user principal for this host. The principal is named like "host/{hostname}@{realm}".

Note, I need to check if this isnt too Hadoop specific, in which case it should 
be moved to "phyla/hadoop/core".

    module.exports.push name: 'Krb5 client # Host Principal', timeout: -1, callback: (ctx, next) ->
      {etc_krb5_conf} = ctx.config.krb5
      modified = false
      each(etc_krb5_conf.realms)
      .on 'item', (realm, config, next) ->
        {kadmin_principal, kadmin_password, admin_server} = config
        # krb5_admin_servers = for realm, config of etc_krb5_conf.realms then  config.admin_server
        # ctx.waitIsOpen krb5_admin_servers, 88, (err) ->
        cmd = misc.kadmin 
          realm: realm
          kadmin_principal: kadmin_principal if admin_server isnt ctx.config.host
          kadmin_password: kadmin_password if admin_server isnt ctx.config.host
          kadmin_server: admin_server if admin_server isnt ctx.config.host
        , 'listprincs'
        # ctx.waitForExecution "kadmin -p #{kadmin_principal} -s #{admin_server} -w #{kadmin_password} -q 'listprincs'", (err) ->
        ctx.waitForExecution cmd, (err) ->
          return next err if err
          ctx.krb5_addprinc
            principal: "host/#{ctx.config.host}@#{realm}"
            randkey: true
            kadmin_principal: kadmin_principal if admin_server isnt ctx.config.host
            kadmin_password: kadmin_password if admin_server isnt ctx.config.host
            kadmin_server: admin_server if admin_server isnt ctx.config.host
          , (err, created) ->
            return next err if err
            modified = true if created
            next()
      .on 'both', (err) ->
        next err, if modified then ctx.OK else ctx.PASS

## Configure SSHD

Updated the "/etc/ssh/sshd\_config" file with properties provided by the "krb5.sshd" 
configuration object. By default, we set the following properties to "yes": "ChallengeResponseAuthentication",
"KerberosAuthentication", "KerberosOrLocalPasswd", "KerberosTicketCleanup", "GSSAPIAuthentication", 
"GSSAPICleanupCredentials". The "sshd" service will be restarted if a change to the configuration is detected.

    module.exports.push name: 'Krb5 client # Configure SSHD', timeout: -1, callback: (ctx, next) ->
      {sshd} = ctx.config.krb5
      return next null, ctx.DISABLED unless sshd
      write = for k, v of sshd
        match: new RegExp "^#{k}.*$", 'mg'
        replace: "#{k} #{v}"
        append: true
      return next null, ctx.DISABLED if write.length is 0
      ctx.log 'Write /etc/ssh/sshd_config'
      ctx.write
        write: write
        destination: '/etc/ssh/sshd_config'
      , (err, written) ->
        return next err if err
        return next null, ctx.PASS unless written
        ctx.log 'Restart openssh'
        ctx.service
          name: 'openssh'
          srv_name: 'sshd'
          action: 'restart'
        , (err, restarted) ->
          next err, ctx.OK

## Usefull client commands

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

