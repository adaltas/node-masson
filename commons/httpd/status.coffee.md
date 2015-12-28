
# HTTPD Web Server Status

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Status

Princ the status for the HTTPD service by executing the command
`service httpd status`.

    exports.push header: 'HTTPD # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'httpd'
        if_exists: '/etc/init.d/httpd'
