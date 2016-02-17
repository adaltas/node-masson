
# HTTPD Web Server

Configure the HTTPD server.

    exports = module.exports = ->
      'configure': [
        'masson/commons/httpd/configure'
      ]
      'check': [
        'masson/commons/httpd/status'
        'masson/commons/httpd/check'
      ]
      'install': [
        'masson/core/iptables'
        'masson/commons/httpd/install'
        'masson/commons/httpd/start'
      ]
      'start': 'masson/commons/httpd/start'
      'status': 'masson/commons/httpd/status'
      'stop': 'masson/commons/httpd/stop'
