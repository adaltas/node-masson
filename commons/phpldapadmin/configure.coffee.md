
# phpLDAPadmin Configure

    module.exports = handler: ->
      options = @config.phpldapadmin ?= {}
      options.config_path ?= '/etc/phpldapadmin/config.php'
      options.config_httpd_path ?= '/etc/httpd/conf.d/phpldapadmin.conf'
