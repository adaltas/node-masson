
# SSSD Intall

    module.exports =
      use:
        yum: module: 'masson/core/yum'
        openldap_client: module: 'masson/core/openldap_client'
      configure: 'masson/core/sssd/configure'
      commands:
        'check': ->
          options = @config.sssd
          @call 'masson/core/sssd/check', options
        'install': ->
          options = @config.sssd
          @call 'masson/core/sssd/install', options
          @call 'masson/core/sssd/start', options
          @call 'masson/core/sssd/check', options
        'start': ->
          options = @config.sssd
          @call 'masson/core/sssd/start', options
        'status': ->
          options = @config.sssd
          @call 'masson/core/sssd/status', options
        'stop': ->
          options = @config.sssd
          @call 'masson/core/sssd/stop', options
