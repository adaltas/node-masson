
# Bind server

Install and configure [named](http://linux.die.net/man/8/named), a 
Domain Name System (DNS) server, part of the BIND 9 distribution f
rom ISC.

    export default
      deps:
        iptables: module: 'masson/core/iptables', local: true
        yum: module: 'masson/core/yum'
      configure:
        'masson/core/bind_server/configure'
      commands:
        'check':
          'masson/core/bind_server/check'
        'install': [
          'masson/core/bind_server/install'
          'masson/core/bind_server/start'
        ]
        'start':
          'masson/core/bind_server/start'
        'stop':
          'masson/core/bind_server/stop'
