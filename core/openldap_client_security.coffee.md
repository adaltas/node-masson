---
title: 
layout: module
---

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/openldap_client'

    module.exports.push module.exports.configure = (ctx) ->
      # Register "ctx.ldap_add" function
      # require('./openldap_client').configure ctx
      {users_container_dn, groups_container_dn, tls_cacertfile, rootpwmoddn, base, bindpw} = ctx.config.openldap_client_security
      ldap_hosts = ctx.hosts_with_module 'masson/core/openldap_server'
      uri = for host in ldap_hosts then "ldap://#{host}"
      # Prepare nslcd configuration
      ctx.config.openldap_client_security.nslcd ?= """
      uid nslcd
      gid ldap
      uri #{uri}
      base #{base}
      binddn cn=nssproxy,#{users_container_dn}
      bindpw #{bindpw}
      rootpwmoddn #{rootpwmoddn}
      base group #{groups_container_dn}
      base passwd #{users_container_dn}
      base shadow #{users_container_dn}
      bind_timelimit 5
      timelimit 10
      idle_timelimit 60
      ssl start_tls
      tls_reqcert never
      tls_cacertfile #{tls_cacertfile.destination}
      nss_initgroups_ignoreusers adm,bin,daemon,dbus,ftp
      nss_initgroups_ignoreusers games,gopher,halt,lp,mail,mailnull
      nss_initgroups_ignoreusers nfsnobody,nobody,nscd,nslcd,ntp,operator
      nss_initgroups_ignoreusers panic,qpidd,root,rpc,rpcuser,saslauth
      nss_initgroups_ignoreusers shutdown,smmsp,sshd,sync,uucp,vcsa
      """
      # Avoid message "line too long or last line missing newline" followed by nslcd restart error
      ctx.config.openldap_client_security.nslcd += '\n'
      ctx.config.openldap_client_security.pam_ldap ?= """
      base      #{base}
      uri       #{uri}
      binddn      cn=nssproxy,#{users_container_dn}
      bindpw      #{bindpw}
      timelimit   15
      bind_timelimit    15
      pam_member_attribute  gidNumber
      nss_base_passwd   #{users_container_dn}?one
      nss_base_shadow   #{users_container_dn}?one
      nss_base_group    #{groups_container_dn}?one
      nss_base_netgroup #{groups_container_dn}?one
      ssl     start_tls
      tls_cacertfile    #{tls_cacertfile.destination}
      """
      ctx.config.openldap_client_security.pam_ldap += '\n'
      ctx.config.openldap_client_security.pamd_sshd ?= """
      auth       sufficient   pam_ldap.so
      auth       required     pam_sepermit.so
      auth       include      password-auth
      account    required     pam_nologin.so
      account    include      password-auth
      password   include      password-auth
      # pam_selinux.so close should be the first session rule
      session    required     pam_selinux.so close
      session    required     pam_loginuid.so
      # pam_selinux.so open should only be followed by sessions to be executed in the user context
      session    required     pam_selinux.so open env_params
      session    optional     pam_keyinit.so force revoke
      session    include      password-auth
      """
      ctx.config.openldap_client_security.pamd_sshd += '\n'
      ctx.config.openldap_client_security.system_auth_ac ?= """
      auth        required      pam_env.so
      auth        sufficient    pam_unix.so nullok try_first_pass
      auth        requisite     pam_succeed_if.so uid >= 500 quiet
      auth        sufficient    pam_ldap.so use_first_pass
      auth        required      pam_deny.so

      account     required      pam_unix.so
      account     sufficient    pam_localuser.so
      account     sufficient    pam_succeed_if.so uid < 500 quiet
      account     [default=bad success=ok user_unknown=ignore] pam_ldap.so
      account     required      pam_permit.so

      password    requisite     pam_cracklib.so try_first_pass retry=3 type=
      password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
      password    sufficient    pam_ldap.so use_authtok
      password    required      pam_deny.so

      session     optional      pam_keyinit.so revoke
      session     required      pam_limits.so
      session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
      session     required      pam_unix.so
      session     optional      pam_ldap.so
      """
      ctx.config.openldap_client_security.system_auth_ac += '\n'

      

    module.exports.push name: 'OpenLDAP ACL # Services', callback: (ctx, next) ->
      ctx.service [
        name: 'openldap'
      ,
        name: 'openldap-clients'
      ,
        name: 'nss-pam-ldapd'
      ,
        name: 'pam_ldap'
      ], (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

    module.exports.push name: 'OpenLDAP ACL # Configure nsswitch', timeout: -1, callback: (ctx, next) ->
      ctx.write
        content: """
        passwd:   files ldap
        shadow:   files ldap
        group:    files ldap
        hosts:    files dns
        ethers:   files
        netmasks: files
        networks: files
        protocols:  files
        rpc:    files
        services: files
        netgroup: ldap
        automount:  files ldap
        aliases:  files
        sudoers:  files ldap

        """
        destination: '/etc/nsswitch.conf'
      , (err, written) ->
        next err, if written then ctx.OK else ctx.PASS

## nslcd

nslcd - local LDAP name service daemon

    module.exports.push name: 'OpenLDAP ACL # Configure nslcd', timeout: -1, callback: (ctx, next) ->
      {nslcd, tls_cacertfile} = ctx.config.openldap_client_security
      ctx.upload tls_cacertfile, (err, uploaded) ->
        return next err if err
        ctx.write
          content: nslcd
          destination: '/etc/nslcd.conf'
        , (err, written) ->
          return next err if err
          # return next err, ctx.PASS if err or (not uploaded and not written)
          ctx.service
            srv_name: 'nslcd'
            chk_name: 'nslcd'
            startup: true
            action: 'restart'
          , (err) ->
            return next err if err
            ctx.execute
              cmd: "getent passwd test"
            , (err, executed) ->
              # Status exit code is 2 on error
              return next err if err
              ctx.execute
                cmd: "getent group test"
              , (err, executed) ->
                # Status exit code is 2 on error
                return next err, ctx.OK

    module.exports.push name: 'OpenLDAP ACL # Configure pam_ldap', timeout: -1, callback: (ctx, next) ->
      {pam_ldap, pamd_sshd, system_auth_ac} = ctx.config.openldap_client_security
      ctx.write [
        content: pam_ldap
        destination: '/etc/pam_ldap.conf'
      ,
        match: new RegExp "^UsePAM\s.*$", 'mg'
        replace: "UsePAM yes"
        append: true
        destination: '/etc/ssh/sshd_config'
      ,
        content: pamd_sshd
        destination: '/etc/pam.d/sshd.conf'
      ,
        content: system_auth_ac
        destination: '/etc/pam.d/system-auth-ac'
      ], (err, written) ->
        next err, if written then ctx.OK else ctx.PASS

            

http://frednotes.wordpress.com/2013/05/25/auto-creation-of-user-home-directories-in-centosrhel-6/
pam_mkhomedir.so is now “deprecated” and is replaced by oddjob 









