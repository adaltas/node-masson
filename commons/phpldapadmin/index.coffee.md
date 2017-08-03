
# phpLDAPadmin

Install the phpLDAPadmin and register it to the Apache HTTPD server. Upon
installation, the web application will be accessible at the following URL:
"http://localhost/ldap".

    module.exports =
      use:
        'httpd': module: 'masson/commons/httpd', local: true
      configure: 'masson/commons/phpldapadmin/configure'
      commands:
        'install': ->
          options = @config.phpldapadmin
          @call 'masson/commons/phpldapadmin/install', options
