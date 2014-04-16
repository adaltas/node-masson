---
title: SSSD
module: masson/core/sssd
layout: module
---

# SSSD

The System Security Services Daemon (SSSD) provides access to different 
identity and authentication providers.

    crypto = require 'crypto'
    each = require 'each'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/openldap_client'

Option includes:   

*   `sssd.certificates` (array)   
    List of certificates to be uploaded to the server.   
*   `sssd.merge`   
    Merge the configuration with the one already present on the server, default 
    to false.
*   `sssd.force_check`   
    Force check commands to be executed on each run, default to false   
*   `sssd.config`   
*   `sssd.certificates`   
*   `sssd.services` (array|string)   
    List of services to install, default to `['sssd', 'sssd-client', 'pam_krb5', 'pam_ldap']`
*   `sssd.test_user`   

Example:

```json
{
  "sssd": {
    "test_user": "test"
    "force_check": true
    "config":
      "domain/my_domain":
        "cache_credentials": "True"
        "ldap_search_base": "ou=users,dc=adaltas,dc=com"
        "ldap_group_search_base": "ou=groups,dc=adaltas,dc=com"
        "id_provider": "ldap"
        "auth_provider": "ldap"
        "chpass_provider": "ldap"
        "ldap_uri": "ldaps://master3.hadoop:636"
        "ldap_tls_cacertdir": "/etc/openldap/cacerts"
        "ldap_default_bind_dn": "cn=Manager,dc=adaltas,dc=com"
        "ldap_default_authtok": "test"
        "ldap_id_use_start_tls": "False"
      "sssd":
        "config_file_version": "2"
        "reconnection_retries": "3"
        "sbus_timeout": "30"
        "services": "nss, pam"
        "domains": "my_domain"
      "nss":
        "filter_groups": "root"
        "filter_users": "root"
        "reconnection_retries": "3"
        "entry_cache_timeout": "300"
        "entry_cache_nowait_percentage": "75"
      "pam":
        "reconnection_retries": "3"
        "offline_credentials_expiration": "2"
        "offline_failed_login_attempts": "3"
        "offline_failed_login_delay": "5"
    "certificates": [
      "#{__dirname}/certs-master3/master3.hadoop.ca.cer"
    ]
  }
}
```

    module.exports.push (ctx) ->
      ctx.config.sssd ?= {}
      ctx.config.sssd.certificates ?= []
      ctx.config.sssd.merge ?= false
      ctx.config.sssd.force_check ?= false
      ctx.config.sssd.config ?= {}
      ctx.config.sssd.services ?= ['sssd', 'sssd-client', 'pam_krb5', 'pam_ldap'] #, 'sssd-tools'
      ctx.config.sssd.services = ctx.config.sssd.services.split ' ' if typeof ctx.config.sssd.services is 'string'
      ctx.config.sssd.test_user ?= null

## Install

Install the services defined by the "sssd.services" property. By default, the 
following service: "sssd", "sssd-client", "pam\_krb5", "pam\_ldap" and 
"sssd-tools".

    module.exports.push name: 'SSSD # Install', timeout: -1, callback: (ctx, next) ->
      {services} = ctx.config.sssd
      services = for name in services then name: name
      ctx.service services, (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

## Certificates

Certificates are temporarily uploaded to the "/tmp" folder and registered with
the command `authconfig --update --ldaploadcacert={file}`.

    module.exports.push name: 'SSSD # Certificates', callback: (ctx, next) ->
      {certificates} = ctx.config.sssd
      modified = false
      each(certificates)
      .on 'item', (certificate, next) ->
        hash = crypto.createHash('md5').update(certificate).digest('hex')
        ctx.upload 
          source: certificate
          destination: "/tmp/#{hash}"
        , (err) ->
          return next err if err
          ctx.execute # openssh is executed remotely
            cmd: "openssl x509 -noout -hash -in /tmp/#{hash}; rm -rf /tmp/#{hash}"
          , (err, _, stdout) ->
            return next err if err
            stdout = stdout.trim()
            ctx.upload 
              source: certificate
              destination: "/etc/openldap/cacerts/#{stdout}.0"
            , (err, uploaded) ->
              return next err if err
              modified = true if uploaded
              next()
      .on 'both', (err) ->
        next err, if modified then ctx.OK else ctx.PASS

## Configure

Update the SSSD configuration file present in "/etc/sssd/sssd.conf" with the 
values defined in the "sssd.config" property. The destination file is by 
default overwritten unless the "sssd.merge" is `true`.

    module.exports.push name: 'SSSD # Configure', timeout: -1, callback: (ctx, next) ->
      {merge, config} = ctx.config.sssd
      ctx.ini
        content: config
        destination: '/etc/sssd/sssd.conf'
        merge: merge
        mode: 0o600
      , (err, written) ->
        # return next err, ctx.PASS unless written
        options =
          # Configures the password, shadow, group, and netgroups services maps to use the SSSD module
          # https://access.redhat.com/site/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/Configuration_Options-NSS_Configuration_Options.html
          sssd: true
          # Create home directories for users on their first login
          mkhomedir: true
          # To use an LDAP identity store, use the --enableldap. To use LDAP as the authentication source, use --enableldapauth.
          # https://access.redhat.com/site/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/ch-Configuring_Authentication.html#sect-The_Authentication_Configuration_Tool-Command_Line_Version
          ldap: false
          ldapauth: false
          # Enable SSSD for system authentication
          # https://access.redhat.com/site/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/Configuration_Options-PAM_Configuration_Options.html
          sssdauth: false
        # Update configuration files with changed settings
        cmd = 'authconfig --update'
        for k, v of options
          cmd += if v then " --enable#{k}" else " --disable#{k}"
        {ldap_uri, ldap_search_base} = config['domain/default']?
        cmd += "--ldapserver=#{ldap_uri}" if ldap_uri
        cmd += "--ldapbasedn=#{ldap_search_base}" if ldap_search_base
        ctx.execute
          cmd: cmd
        , (err, executed) ->
          return next err if err
          ctx.service
            name: 'sssd'
            action: 'restart'
          , (err, restarted) ->
            next err, if written then ctx.OK else ctx.PASS

## Check NSS

Check if NSS is correctly configured by executing the command `getent passwd 
$user`. The command is only executed if a test user is defined by the 
"sssd.test_user" property.

    module.exports.push name: 'SSSD # Check NSS', callback: (ctx, next) ->
      {test_user, force_check} = ctx.config.sssd
      return next() unless test_user
      ctx.fs.exists '/var/db/masson/sssd_getent_passwd', (err, exists) ->
        return next err, ctx.PASS if (err or exists) and not force_check
        ctx.execute
          cmd: "getent passwd #{test_user}"
        , (err, executed, stdout, stderr) ->
          return next err if err
          ctx.touch
            destination: '/var/db/masson/sssd_getent_passwd'
          , (err, written) ->
            next err, ctx.OK

## Check PAM

Check if PAM is correctly configured by executing the command 
`sh -l $user -c 'touch .masson_check_pam'`. This is only executed if a test 
user is defined by the "sssd.test_user" property.

    module.exports.push name: 'SSSD # Check PAM', callback: (ctx, next) ->
      {test_user, force_check} = ctx.config.sssd
      return next() unless test_user
      ctx.execute
        cmd: "su -l #{test_user} -c 'touch .masson_check_pam'"
        not_if_exists: if force_check then null else "/home/#{test_user}/.masson_check_pam"
      , (err, executed, stdout, stderr) ->
        return next err, if executed then ctx.OK else ctx.PASS
        
      
      




















