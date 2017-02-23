
#  OpenLDAP Server Check

    module.exports = header: 'OpenLDAP Server Check', label_true: 'CHECKED', handler: ->
      {openldap_server} = @config
      @system.execute
        cmd: "ldapsearch -x -H ldaps://#{@config.host} -b #{openldap_server.suffix} -D #{openldap_server.root_dn} -w #{openldap_server.root_password}"
