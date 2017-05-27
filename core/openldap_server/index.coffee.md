
# OpenLDAP Server

    module.exports =
      use:
        # TODO: manually activate iptables after removal of implicit: true,
        iptables: module: 'masson/core/iptables'
        # network: module: 'masson/core/network'
        saslauthd: module: 'masson/core/saslauthd'
      configure: [
        'masson/core/openldap_server/configure'
        # 'masson/core/openldap_client/configure'
      ]
      commands:
        'check':
          'masson/core/openldap_server/check'
        'install': [
          'masson/core/openldap_server/install'
          'masson/core/openldap_server/install_tls'
          'masson/core/openldap_server/install_krb5'
          'masson/core/openldap_server/install_ha'
          'masson/core/openldap_server/install_sasl'
          'masson/core/openldap_server/install_entries'
        ]
        'start':
          'masson/core/openldap_server/start'
        'stop':
          'masson/core/openldap_server/stop'
        'backup':
          'masson/core/openldap_server/backup'
