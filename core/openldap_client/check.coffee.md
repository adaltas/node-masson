
# OpenLDAP Client Check

Make sure we can execute the command `ldapsearch` with the default URL found
inside "/etc/openldap/ldap.conf". The success of the test rely on the command
exit code.

    module.exports = header: 'OpenLDAP Client Check', label_true: 'CHECKED', handler: ->

## Wait

Wait for OpenLDAP servers to start.

      @call 'masson/core/openldap_client/wait'

## Check Search

      {suffix, root_dn, root_password} = @config.openldap_client
      @execute
        retry: 3
        header: 'Search'
        if: -> suffix
        cmd: "ldapsearch -x -D #{root_dn} -w #{root_password} -b '#{suffix}'"
        stdout: null # Desactive stdout output in logs
