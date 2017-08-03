
# Kerberos Server

Kerberos is a network authentication protocol. It is designed to provide strong
authentication for client/server applications by using secret-key cryptography.
The module install the free implementation of this protocol available from the
Massachusetts Institute of Technology.

The article [SSH Kerberos Authentication Using GSSAPI and SSPI][gss_sspi]
provides a good description on how Kerberos is negotiated by GSSAPI and SSPI.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables/configure', local: true
        openldap_client: module: 'masson/core/openldap_client', local: true, auto: true, implicit: true
        openldap_server:  module: 'masson/core/openldap_server', min: 1, max: 2
        krb5_server:  module: 'masson/core/krb5_server'
      configure:
        'masson/core/krb5_server/configure'
      commands:
        'check': ->
          options = @config.krb5_server
          @call 'masson/core/krb5_server/check', options
        'install': ->
          options = @config.krb5_server
          @call 'masson/core/krb5_server/install', options
          @call 'masson/core/krb5_server/start', options
          @call 'masson/core/krb5_server/check', options
        # 'reload':
        #   'masson/core/krb5_server/install'
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
