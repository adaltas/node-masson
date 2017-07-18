
# phpLDAPadmin

Install the phpLDAPadmin and register it to the Apache HTTPD server. Upon
installation, the web application will be accessible at the following URL:
"http://localhost/ldap".

    module.exports = ->
      use:
        implicit: true, module: 'masson/commons/httpd'
      configure: 'masson/commons/phpldapadmin/configure'
      commands:
        'install': 'masson/commons/phpldapadmin/install'
