
# phpLDAPadmin Configure

    module.exports = handler: ->
      @config.phpldapadmin ?= {}
      @config.phpldapadmin.config_path ?= '/etc/phpldapadmin/config.php'
      @config.phpldapadmin.config_httpd_path ?= '/etc/httpd/conf.d/phpldapadmin.conf'
