
# Bind server

Install and configure [named](http://linux.die.net/man/8/named), a 
Domain Name System (DNS) server, part of the BIND 9 distribution f
rom ISC.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        yum: module: 'masson/core/yum'
      configure:
        'masson/core/bind_server/configure'
      commands:
        'check': ->
          options = @config.bind_server
          @call 'masson/core/bind_server/check', options
        'install': ->
          options = @config.bind_server
          @call 'masson/core/bind_server/install', options
          @call 'masson/core/bind_server/start', options
        'start':
          'masson/core/bind_server/start'
        'stop':
          'masson/core/bind_server/stop'
