
# phpLDAPadmin

Install the phpLDAPadmin and register it to the Apache HTTPD server. Upon
installation, the web application will be accessible at the following URL:
"http://localhost/ldap".

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/yum'
    exports.push 'masson/commons/httpd'

    exports.push (ctx) ->
      ctx.config.phpldapadmin ?= {}
      ctx.config.phpldapadmin.config_path ?= '/etc/phpldapadmin/config.php'
      ctx.config.phpldapadmin.config_httpd_path ?= '/etc/httpd/conf.d/phpldapadmin.conf'

## Install

Install the "phpldapadmin" package.

    exports.push name: 'phpLDAPadmin # Install', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'phpldapadmin'
      , next

## Configure

Configure the application. The configuration file is defined by the
"phpldapadmin.config_path" property (default to "/etc/phpldapadmin/config.php").

    exports.push name: 'phpLDAPadmin # Configure', handler: (ctx, next) ->
      ctx.write
        write: [
          {match: /^(\/\/)(.*'login','attr','dn'.*)$/m, replace: '$2'}
          {match: /^(?!\/\/)(.*'login','attr','uid'.*)$/m, replace: '//$1'}
        ],
        destination: ctx.config.phpldapadmin.config_path
        backup: true
      , (err, written) ->
        return next err,false if err or not written
        ctx.service
          name: 'httpd'
          action: 'restart'
        , (err, serviced) ->
          next err, true

## HTTPD

Register phpLDAPAdmin into the Apache HTTPD server. It modify the file defined
by the "phpldapadmin.config_httpd_path" property (default to 
"/etc/httpd/conf.d/phpldapadmin.conf") and made the application visible under
the "http://{host}/ldapadmin" URL path.

    exports.push name: 'phpLDAPadmin # HTTPD', handler: (ctx, next) ->
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
        return next null, false unless written
        ctx.service
          name: 'httpd'
          action: 'restart'
        , (err, serviced) ->
          next err, true
