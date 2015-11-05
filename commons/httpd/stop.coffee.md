
# HTTPD Web Server Stop

    exports = module.exports = []

## Stop

Start the HTTPD service by executing the command `service httpd stop`.

    exports.push header: 'HTTPD # Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'httpd'
