
# HTTPD Web Server Status

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Status

Princ the status for the HTTPD service by executing the command
`service httpd status`.

    exports.push header: 'HTTPD # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: "service httpd status"
        code_skipped: 3
        if_exists: '/etc/init.d/httpd'
