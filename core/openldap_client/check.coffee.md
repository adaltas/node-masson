
# OpenLDAP Client Check

Make sure we can execute the command `ldapsearch` with the default URL found
inside "/etc/openldap/ldap.conf". The success of the test rely on the command
exit code.

    export default header: 'OpenLDAP Client Check', handler: ({options}) ->

## Wait

Wait for OpenLDAP servers to start.

      @call 'masson/core/openldap_client/wait', options.wait

## Check Search

      @system.execute
        retry: 3
        header: 'Search'
        if: -> options.check.suffix
        cmd: """
        ldapsearch -x \
          -D '#{options.check.root_dn}' \
          -w '#{options.check.root_password}' \
          -b '#{options.check.suffix}'
        """
        stdout: null # Desactive stdout output in logs
