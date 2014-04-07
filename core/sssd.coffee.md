---
title: 
layout: module
---

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/openldap_client'

    module.exports.push (ctx) ->
      ctx.config.sssd ?= {}
      ctx.config.sssd.tools ?= true
      ctx.config.sssd.certificates ?= {}
      # ctx.config.sssd.certificates_dir ?= '/etc/openldap/cacerts/'
      ctx.config.sssd.config ?= {}
      ctx.config.sssd.config_path ?= '/etc/sssd/sssd.conf'

    module.exports.push name: 'SSSD # Install', timeout: -1, callback: (ctx, next) ->
      {tools} = ctx.config.sssd
      names = ['sssd', 'sssd-client', 'pam_krb5', 'pam_ldap']
      names.push 'sssd-tools' if tools
      services = for name in names
        name: name
      ctx.service services, (err, serviced) ->
        ctx.log "Services installed: #{serviced}"
        next err, if serviced then ctx.OK else ctx.PASS

    # module.exports.push (ctx, next) ->
    #   @name 'SSSD # Push certificates'
    #   {certificates} = ctx.config.sssd
    #   certs = for name, content of certificates
    #     destination: "#{name}"
    #     content: content
    #   ctx.write certs, (err, written) ->
    #     next err, if written then ctx.OK else ctx.PASS

    module.exports.push name: 'SSSD # Configure', timeout: -1, callback: (ctx, next) ->
      {ldap_uri, config, config_path} = ctx.config.sssd
      ctx.log "Place original sssd config file"
      ctx.execute
        cmd: 'cp -p /usr/share/doc/sssd-$(echo $(rpm -qa sssd) | sed -E "s/.*\\-(.*)-.*/\\1/")/sssd-example.conf /etc/sssd/sssd.conf && chmod 600 /etc/sssd/sssd.conf'
        not_if_exists: '/etc/sssd/sssd.conf'
      , (err, copied) ->
        return next err if err
        ctx.log "Was original sssd config file copied: #{copied}"
        ctx.log "Update #{config_path}"
        ctx.ini
          content: config
          destination: config_path
          merge: true
        , (err, written) ->
          return next err, ctx.PASS unless written
          ctx.log 'Restart sssd'
          # Note: we dont detect a change when executing authconfig
          # "--enablecachecreds --enablecache" require "nscd"
          cmd = """
          authconfig \\
            --enableshadow --nostart  \\
            --enablesssd --enablesssdauth --enablelocauthorize \\
            --enableldap --enableldaptls --enableldapauth \\
            --ldapserver=#{ldap_uri} --ldapbasedn=dc=adaltas,dc=com\\
            --enablekrb5 \\
            --kickstart --enablemkhomedir \\
            --updateall
          """
          ctx.log "Run #{cmd}"
          ctx.execute
            cmd: cmd
          , (err, executed) ->
            return next err if err
            ctx.service
              name: 'sssd'
              action: 'restart'
            , (err, restarted) ->
              next err, ctx.OK



