
# OpenLDAP Client Check

Make sure we can execute the command `ldapsearch` with the default URL found
inside "/etc/openldap/ldap.conf". The success of the test rely on the command
exit code.

    module.exports = header: 'OpenLDAP Client Check', label_true: 'CHECKED', handler: ->
      [openldap_server_ctx] = @contexts 'masson/core/openldap_server'
      {suffix, root_dn, root_password} = openldap_server_ctx.config.openldap_server

## Wait

Wait for OpenLDAP servers to start.

      @call 'masson/core/openldap_client/wait'

## Check Search

      @execute
        retry: 3
        header: 'Search'
        if: -> suffix
        cmd: "ldapsearch -x -D #{root_dn} -w #{root_password} -b '#{suffix}'"
        stdout: null # Desactive stdout output in logs
