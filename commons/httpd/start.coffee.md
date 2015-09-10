
# HTTPD Web Server Start

    exports = module.exports = []

## Start

Start the HTTPD service by executing the command `service httpd start`.

    exports.push name: 'HTTPD # Start', label_true: 'STARTED', handler: ->
      {action} = @config.httpd
      @service
        srv_name: 'httpd'
        action: action
