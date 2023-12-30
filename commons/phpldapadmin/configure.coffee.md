
# phpLDAPadmin Configure

    export default (service) ->
      options = service.options
      
      options.config_path ?= '/etc/phpldapadmin/config.php'
      options.config_httpd_path ?= '/etc/httpd/conf.d/phpldapadmin.conf'
