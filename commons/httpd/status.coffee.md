
# HTTPD Web Server Status

Print the status for the HTTPD service.

    module.exports = header: 'HTTPD # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'httpd'
        if_exists: '/etc/init.d/httpd'
