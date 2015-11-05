
# OpenLDAP Client

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/openldap_client/wait'
    # exports.push require('./index').configure

## Check Search

Make sure we can execute the command `ldapsearch` with the default URL found
inside "/etc/openldap/ldap.conf". The success of the test rely on the command
exit code.

    exports.push
      header: 'OpenLDAP Client # Check Search'
      label_true: 'CHECKED'
      if: -> @config.openldap_client.suffix
      handler: ->
        {suffix, root_dn, root_password} = @config.openldap_client
        return next() unless suffix
        @execute
          cmd: "ldapsearch -x -D #{root_dn} -w #{root_password} -b '#{suffix}'"
          stdout: null # Desactive stdout output in logs
