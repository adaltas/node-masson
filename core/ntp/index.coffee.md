
# NTP

Network Time Protocol (NTP) is a networking protocol for clock synchronization
between computer systems over packet-switched, variable-latency data networks.

Note, in a VirtualBox environnemnet (including with Vagrant), you might enforce
the clock of the virtual box with the command 
`VBoxManage modifyvm ${vmname} --biossystemtimeoffset -0`.

    export default
      deps:
        network: 'masson/core/network'
      configure:
        'masson/core/ntp/configure'
      commands:
        'check':
          'masson/core/ntp/check'
        'install': [
          'masson/core/ntp/install'
          'masson/core/ntp/start'
          'masson/core/ntp/check'
        ]
        'start':
          'masson/core/ntp/start'
        'stop':
          'masson/core/ntp/stop'
