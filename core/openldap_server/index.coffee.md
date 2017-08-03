
# OpenLDAP Server

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        saslauthd: module: 'masson/core/saslauthd', local: true
        ssl: module: 'masson/core/ssl', local: true
        openldap_server: module: 'masson/core/openldap_server'
      configure:
        'masson/core/openldap_server/configure'
      commands:
        'check': ->
          options = @config.openldap_server
          @call 'masson/core/openldap_server/check', options
        'install': ->
          options = @config.openldap_server
          @call 'masson/core/openldap_server/install', options
          @call 'masson/core/openldap_server/install_tls', options
          @call 'masson/core/openldap_server/install_krb5', options
          @call 'masson/core/openldap_server/install_ha', options
          @call 'masson/core/openldap_server/install_sasl', options
          @call 'masson/core/openldap_server/install_entries', options
          @call 'masson/core/openldap_server/check', options
        'start':
          'masson/core/openldap_server/start'
        'stop':
          'masson/core/openldap_server/stop'
        'backup':
          'masson/core/openldap_server/backup'
