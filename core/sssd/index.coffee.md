
# SSSD Intall

    module.exports =
      use:
        yum: module: 'masson/core/yum'
        openldap_client: module: 'masson/core/openldap_client'
      configure: 'masson/core/sssd/configure'
      commands:
        'check': ->
          options = @coonfig.sssd
          @call 'masson/core/sssd/check', options
        'install': ->
          options = @coonfig.sssd
          @call 'masson/core/sssd/install', options
          @call 'masson/core/sssd/start', options
          @call 'masson/core/sssd/check', options
        'start': 'masson/core/sssd/start'
        'status': 'masson/core/sssd/status'
        'stop': 'masson/core/sssd/stop'
