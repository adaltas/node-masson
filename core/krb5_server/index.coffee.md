
## Kerberos Server

Kerberos is a network authentication protocol. It is designed to provide strong
authentication for client/server applications by using secret-key cryptography.
The module install the free implementation of this protocol available from the
Massachusetts Institute of Technology.

The article [SSH Kerberos Authentication Using GSSAPI and SSPI][gss_sspi]
provides a good description on how Kerberos is negotiated by GSSAPI and SSPI.

    module.exports = ->
      'configure': [
        'masson/core/krb5_client'
        'masson/core/iptables/configure'
        'masson/core/krb5_server/configure'
      ]
      'install': [
        'masson/core/openldap_client'
        'masson/core/iptables'
        'masson/core/krb5_server/install'
        'masson/core/krb5_server/start'
      ]
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

    module.exports.safe_etc_krb5_conf = (etc_krb5_conf) ->
      etc_krb5_conf = misc.merge {}, etc_krb5_conf
      for realm, config of etc_krb5_conf.realms
        delete config.kadmin_principal
        delete config.kadmin_password
        delete config.principals
      for name, config of etc_krb5_conf.dbmodules
        delete config.kdc_master_key
        delete config.manager_dn
        delete config.manager_password
        delete config.ldap_kdc_password
        delete config.ldap_kadmind_password
      etc_krb5_conf

## Dependencies

    misc = require 'mecano/lib/misc'

[gss_sspi]: http://www.drdobbs.com/ssh-kerberos-authentication-using-gssapi/184402071
