
# HTTPD Web Server

Configure the HTTPD server.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
      configure:
        'masson/commons/httpd/configure'
      commands:
        'check': ->
          options = @config.httpd
          @call 'masson/commons/httpd/status', options
          @call 'masson/commons/httpd/check', options
        'install': ->
          options = @config.httpd
          @call 'masson/commons/httpd/install', options
          @call 'masson/commons/httpd/start', options
        'start':
          'masson/commons/httpd/start'
        'status':
          'masson/commons/httpd/status'
        'stop':
          'masson/commons/httpd/stop'
