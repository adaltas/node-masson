
# Kerberos Server

Kerberos is a network authentication protocol. It is designed to provide strong
authentication for client/server applications by using secret-key cryptography.
The module install the free implementation of this protocol available from the
Massachusetts Institute of Technology.

The article [SSH Kerberos Authentication Using GSSAPI and SSPI][gss_sspi]
provides a good description on how Kerberos is negotiated by GSSAPI and SSPI.

    export default
      deps:
        iptables: module: 'masson/core/iptables', local: true
        openldap_client: module: 'masson/core/openldap_client', local: true, auto: true
        openldap_server:  module: 'masson/core/openldap_server', min: 1, max: 2
        krb5_server:  module: 'masson/core/krb5_server'
        rngd:  module: 'masson/core/rngd'
      configure:
        'masson/core/krb5_server/configure'
      commands:
        'check':
          'masson/core/krb5_server/check'
        'install': [
          'masson/core/krb5_server/install'
          'masson/core/krb5_server/start'
          'masson/core/krb5_server/check'
        ]
        'start':
          'masson/core/krb5_server/start'
        'status':
          'masson/core/krb5_server/status'
        'stop':
          'masson/core/krb5_server/stop'
        'backup':
          'masson/core/krb5_server/backup'

[gss_sspi]: http://www.drdobbs.com/ssh-kerberos-authentication-using-gssapi/184402071
