
# Network

Modify the various network related configuration files such as
"/etc/hosts" and "/etc/resolv.conf".

    module.exports =
      use:
        bind_server: 'masson/core/bind_server'
      configure:
        'masson/core/network/configure'
      commands:
        'check': [
          'masson/core/bind_client'
          'masson/core/network/check'
        ]
        'install':
          'masson/core/network/install'
        'restart':
          'masson/core/network/restart'
