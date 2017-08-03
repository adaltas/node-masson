
# NTP

Network Time Protocol (NTP) is a networking protocol for clock synchronization
between computer systems over packet-switched, variable-latency data networks.

Note, in a VirtualBox environnemnet (including with Vagrant), you might enforce
the clock of the virtual box with the command 
`VBoxManage modifyvm ${vmname} --biossystemtimeoffset -0`.

    module.exports =
      use:
        network: 'masson/core/network'
      configure:
        'masson/core/ntp/configure'
      commands:
        'check': ->
          options = @config.ntp
          @call 'masson/core/ntp/check', options
        'install': ->
          options = @config.ntp
          @call 'masson/bootstrap/fs', options
          @call 'masson/core/ntp/install', options
          @call 'masson/core/ntp/start', options
          @call 'masson/core/ntp/check', options
        'start':
          'masson/core/ntp/start'
        'stop':
          'masson/core/ntp/stop'
