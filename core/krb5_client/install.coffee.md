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

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/ssh'
    module.exports.push 'masson/core/ntp'
    module.exports.push 'masson/core/openldap_client'
    module.exports.push require('./index').configure

## Install

The package "krb5-workstation" is installed.

    module.exports.push name: 'Krb5 Client # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service
        name: 'krb5-workstation'
      , next

## Configure

Modify the Kerberos configuration file in "/etc/krb5.conf". Note, 
this action wont be run if the server host a Kerberos server. 
This is to avoid any conflict where both modules would try to write 
their own configuration one. We give the priority to the server module 
which create a Kerberos file with complementary information.

    module.exports.push name: 'Krb5 Client # Configure', timeout: -1, callback: (ctx, next) ->
      # Kerberos config is also managed by the kerberos server action.
      ctx.log 'Check who manage /etc/krb5.conf'
      return next() if ctx.has_module 'masson/core/krb5_server'
      {etc_krb5_conf} = ctx.config.krb5
      ctx.ini
        content: safe_etc_krb5_conf etc_krb5_conf
        destination: '/etc/krb5.conf'
        stringify: misc.ini.stringify_square_then_curly
      , next

## Host Principal

Create a user principal for this host. The principal is named like 
"host/{hostname}@{realm}". Only apply to the default realm 
("krb5.etc\_krb5\_conf.libdefaults.default_realm") unless the property
"etc_krb5_conf[realm].create\_hosts" is set.

    module.exports.push name: 'Krb5 Client # Host Principal', timeout: -1, callback: (ctx, next) ->
      {etc_krb5_conf} = ctx.config.krb5
      default_realm = etc_krb5_conf.libdefaults.default_realm
      modified = false
      each(etc_krb5_conf.realms)
      .on 'item', (realm, config, next) ->
        return next() unless default_realm is realm or not config.create_hosts
        {kadmin_principal, kadmin_password, admin_server} = config
        cmd = misc.kadmin
          realm: realm
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server
        , 'listprincs'
        ctx.waitForExecution cmd, (err) ->
          return next err if err
          ctx.krb5_addprinc
            principal: "host/#{ctx.config.host}@#{realm}"
            randkey: true
            # kadmin_principal: kadmin_principal if admin_server isnt ctx.config.host
            # kadmin_password: kadmin_password if admin_server isnt ctx.config.host
            # kadmin_server: admin_server if admin_server isnt ctx.config.host
            kadmin_principal: kadmin_principal
            kadmin_password: kadmin_password
            kadmin_server: admin_server
          , (err, created) ->
            return next err if err
            modified = true if created
            next()
      .on 'both', (err) ->
        next err, modified

## principals

Populate the Kerberos database with new principals.

    module.exports.push name: 'Krb5 Client # Principals', callback: (ctx, next) ->
      {etc_krb5_conf} = ctx.config.krb5
      modified = false
      utils = require 'util'
      each(etc_krb5_conf.realms)
      .on 'item', (realm, config, next) ->
        {kadmin_principal, kadmin_password, admin_server, principals} = config
        return next() unless principals?.length > 0
        principals = for principal in principals
          misc.merge
            kadmin_principal: kadmin_principal
            kadmin_password: kadmin_password
            kadmin_server: admin_server
          , principal
        ctx.log "Create principal #{principal.principal}"
        ctx.krb5_addprinc principals, (err, created) ->
          return next err if err
          modified = true if created
          next()
      .on 'both', (err) ->
        next err, modified

## Configure SSHD

Updated the "/etc/ssh/sshd\_config" file with properties provided by the "krb5.sshd" 
configuration object. By default, we set the following properties to "yes": "ChallengeResponseAuthentication",
"KerberosAuthentication", "KerberosOrLocalPasswd", "KerberosTicketCleanup", "GSSAPIAuthentication", 
"GSSAPICleanupCredentials". The "sshd" service will be restarted if a change to the configuration is detected.

    module.exports.push name: 'Krb5 Client # Configure SSHD', timeout: -1, callback: (ctx, next) ->
      {sshd} = ctx.config.krb5
      return next() unless sshd
      write = for k, v of sshd
        match: new RegExp "^#{k}.*$", 'mg'
        replace: "#{k} #{v}"
        append: true
      return next() if write.length is 0
      ctx.log 'Write /etc/ssh/sshd_config'
      ctx.write
        write: write
        destination: '/etc/ssh/sshd_config'
      , (err, written) ->
        return next err if err
        return next null, false unless written
        ctx.log 'Restart openssh'
        ctx.service
          name: 'openssh'
          srv_name: 'sshd'
          action: 'restart'
        , (err, restarted) ->
          next err, true

## Module Dependencies

    each = require 'each'
    misc = require 'mecano/lib/misc'
    {safe_etc_krb5_conf} = require './index'

## Usefull Client Commands

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


