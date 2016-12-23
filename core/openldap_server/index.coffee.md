
# OpenLDAP Server

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        iptables: module: 'masson/core/network'
      configure: [
        'masson/core/openldap_server/configure'
        'masson/core/openldap_client/configure'
      ]
      commands:
        'check':
          'masson/core/openldap_server/check'
        'install': [
          'masson/bootstrap/fs'
          'masson/core/openldap_server/install'
          'masson/core/openldap_server/install_tls'
          'masson/core/openldap_client/install'
          'masson/core/openldap_server/install_krb5'
          'masson/core/openldap_server/start'
          'masson/core/openldap_server/check'
        ]
        'start':
          'masson/core/openldap_server/start'
        'stop':
          'masson/core/openldap_server/stop'
        'backup':
          'masson/core/openldap_server/backup'
