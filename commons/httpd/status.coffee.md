
# HTTPD Web Server Status

Print the status for the HTTPD service.

    module.exports = header: 'HTTPD Status', handler: ->
      @service.status
        name: 'httpd'
        if_exists: '/etc/init.d/httpd'
