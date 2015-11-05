
# HTTPD Web Server Start

    exports = module.exports = []

## Start

Start the HTTPD service by executing the command `service httpd start`.

    exports.push header: 'HTTPD # Start', label_true: 'STARTED', handler: ->
      @service_start name: 'httpd'
