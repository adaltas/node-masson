
## Kerberos Server

Kerberos is a network authentication protocol. It is designed to provide strong
authentication for client/server applications by using secret-key cryptography.
The module install the free implementation of this protocol available from the
Massachusetts Institute of Technology.

The article [SSH Kerberos Authentication Using GSSAPI and SSPI][gss_sspi]
provides a good description on how Kerberos is negotiated by GSSAPI and SSPI.

    module.exports =
      use:
        iptables: 'masson/core/iptables/configure'
        openldap_client: implicit: true, module: 'masson/core/openldap_client'
        openldap_server: 'masson/core/openldap_server'
        krb5_server: 'masson/core/krb5_server'
      configure:
        'masson/core/krb5_server/configure'
      commands:
        'install': ->
          options = @config.krb5_server
          @call 'masson/bootstrap/fs', options
          @call 'masson/core/krb5_server/install', options
          @call 'masson/core/krb5_server/start', options
        'reload':
          'masson/core/krb5_server/install'
        'start':
          'masson/core/krb5_server/start'
        'status':
          'masson/core/krb5_server/status'
        'stop':
          'masson/core/krb5_server/stop'
        'backup':
          'masson/core/krb5_server/backup'

## Dependencies

    misc = require 'nikita/lib/misc'

[gss_sspi]: http://www.drdobbs.com/ssh-kerberos-authentication-using-gssapi/184402071
