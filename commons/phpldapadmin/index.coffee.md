
# phpLDAPadmin

Install the phpLDAPadmin and register it to the Apache HTTPD server. Upon
installation, the web application will be accessible at the following URL:
"http://localhost/ldap".

    module.exports = ->
      'configure': 'masson/commons/phpldapadmin/configure'
      'install': [
        'masson/commons/httpd'
        'masson/commons/phpldapadmin/install'
      ]
