
# SSSD Intall

    export default
      use:
        yum: module: 'masson/core/yum'
        openldap_client: module: 'masson/core/openldap_client'
      configure:
        'masson/core/sssd/configure'
      commands:
        'check':
          'masson/core/sssd/check'
        'install': [
          'masson/core/sssd/install'
          'masson/core/sssd/start'
          'masson/core/sssd/check'
        ]
        'start':
          'masson/core/sssd/start'
        'status':
          'masson/core/sssd/status'
        'stop':
          'masson/core/sssd/stop'
