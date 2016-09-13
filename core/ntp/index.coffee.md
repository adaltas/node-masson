
# NTP

Network Time Protocol (NTP) is a networking protocol for clock synchronization
between computer systems over packet-switched, variable-latency data networks.

    module.exports =
      configure:
        'masson/core/ntp/configure'
      commands:
        'check':
          'masson/core/ntp/check'
        'install': [
          'masson/bootstrap/fs'
          'masson/core/ntp/install'
          'masson/core/ntp/start'
          'masson/core/ntp/check'
        ]
        'start':
          'masson/core/ntp/start'
        'stop':
          'masson/core/ntp/stop'
