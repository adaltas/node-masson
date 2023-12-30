
# phpLDAPadmin Install

    export default header: 'phpLDAPadmin Install', handler: (options) ->

## Package

Install the "phpldapadmin" package.

      @service
        name: 'phpldapadmin'

## Configure

Configure the application. The configuration file is defined by the
"phpldapadmin.config_path" property (default to "/etc/phpldapadmin/config.php").

      @file
        header: 'Configure'
        write: [
          {match: /^(\/\/)(.*'login','attr','dn'.*)$/m, replace: '$2'}
          {match: /^(?!\/\/)(.*'login','attr','uid'.*)$/m, replace: '//$1'}
        ],
        target: options.config_path
        backup: true
      @service
        name: 'httpd'
        state: 'restarted'
        if: -> @status -1

## HTTPD

Register phpLDAPAdmin into the Apache HTTPD server. It modify the file defined
by the "phpldapadmin.config_httpd_path" property (default to 
"/etc/httpd/conf.d/phpldapadmin.conf") and made the application visible under
the "http://{host}/ldapadmin" URL path.

      @file
        header: 'HTTPD'
        target: options.config_httpd_path
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
      @service
        name: 'httpd'
        state: 'restarted'
        if: @status -1
