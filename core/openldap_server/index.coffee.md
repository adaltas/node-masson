
# OpenLDAP Server

    export default
      deps:
        iptables: module: 'masson/core/iptables', local: true
        saslauthd: module: 'masson/core/saslauthd', local: true
        ssl: module: '@rybajs/tools/ssl', local: true
        network: module: 'masson/core/network'
        openldap_server: module: 'masson/core/openldap_server'
      configure:
        'masson/core/openldap_server/configure'
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
          'masson/core/openldap_server/check'
        ]
        'start':
          'masson/core/openldap_server/start'
        'stop':
          'masson/core/openldap_server/stop'
        'backup':
          'masson/core/openldap_server/backup'
