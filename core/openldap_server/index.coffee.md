
# OpenLDAP Server

    module.exports = ->
      'configure': [
        'masson/core/iptables'
        'masson/core/openldap_server/configure'
      ]
      'check':
        'masson/core/openldap_server/check'
      'install': [
        'masson/bootstrap/fs'
        'masson/core/iptables'
        'masson/core/openldap_server/install'
        'masson/core/openldap_client/install'
        'masson/core/openldap_server/install_tls'
        'masson/core/openldap_server/install_acl'
        'masson/core/openldap_server/start'
        'masson/core/openldap_server/check'
      ]
      'start':
        'masson/core/openldap_server/start'
      'stop':
        'masson/core/openldap_server/stop'
      'backup':
        'masson/core/openldap_server/backup'
