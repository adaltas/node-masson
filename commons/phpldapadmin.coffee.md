---
title: 
layout: module
---

# phpLDAPadmin

http://www.server-world.info/en/note?os=CentOS_6&p=ldap&f=4

http://localhost/phpldapadmin
http://localhost/ldap

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/commons/httpd'

    module.exports.push (ctx) ->
      ctx.config.phpldapadmin ?= {}
      ctx.config.phpldapadmin.config_path ?= '/etc/phpldapadmin/config.php'
      ctx.config.phpldapadmin.config_httpd_path ?= '/etc/httpd/conf.d/phpldapadmin.conf'

    module.exports.push name: 'phpLDAPadmin # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service
        name: 'phpldapadmin'
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

    module.exports.push name: 'phpLDAPadmin # Configure', timeout: 100000, callback: (ctx, next) ->
      ctx.write
        match: /^(\/\/)(.*'login','attr','dn'.*)$/m
        replace: '$2'
        destination: ctx.config.phpldapadmin.config_path
        backup: true
      , (err, w1) ->
        return next err if err
        ctx.write
          ssh: ctx.ssh
          match: /^(?!\/\/)(.*'login','attr','uid'.*)$/m
          replace: '//$1'
          destination: ctx.config.phpldapadmin.config_path
          backup: true
        , (err, w2) ->
          return next err if err
          return next null, ctx.PASS unless w1 or w2
          ctx.service
            name: 'httpd'
            action: 'restart'
          , (err, serviced) ->
            next err, ctx.OK

    module.exports.push name: 'phpLDAPadmin # HTTPD', timeout: 100000, callback: (ctx, next) ->
      ctx.write
        destination: ctx.config.phpldapadmin.config_httpd_path
        write: [
          match: /^(?!#)(.*Alias \/phpldapadmin.*)$/m
          replace: '#$1'
        ,
          match: /^(?!#)(.*Alias \/ldapadmin.*)$/m
          replace: '#$1'
        ,
          match: /^(?!#)(Alias \/ldap)(.*)$/m
          replace: "Alias /ldap /usr/share/phpldapadmin/htdocs"
          append: 'Alias /ldapadmin'
        ,
          match: /^.*(?!#).*(Deny from all)$/m
          replace: '  #$1'
        ,
          match: /^.*(?!#).*(Allow from 127\.0\.0\.1)$/m
          replace: '  #$1'
        ,
          match: /^.*(?!#).*(Allow from ::1)$/m
          replace: '  $1'
        ,
          match: /^.*(?!#).*(Allow from all)$/m
          replace: '  Allow from all'
          append: 'Allow from ::1'
        ]
        backup: true
      , (err, written) ->
        return next err if err
        return next null, ctx.PASS unless written
        ctx.service
          name: 'httpd'
          action: 'restart'
        , (err, serviced) ->
          next err, ctx.OK
