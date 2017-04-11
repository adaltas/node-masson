
# HTTPD Web Server

Configure the HTTPD server.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables' # implicit: true
      configure:
        'masson/commons/httpd/configure'
      commands:
        'check': [
          'masson/commons/httpd/status'
          'masson/commons/httpd/check'
        ]
        'install': [
          'masson/commons/httpd/install'
          'masson/commons/httpd/start'
        ]
        'start':
          'masson/commons/httpd/start'
        'status':
          'masson/commons/httpd/status'
        'stop':
          'masson/commons/httpd/stop'
