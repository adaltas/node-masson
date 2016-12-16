
# HTTPD Web Server Start

Start the HTTPD service by executing the command `service httpd start`.

    module.exports = header: 'HTTPD Start', label_true: 'STARTED', handler: ->
      @service.start name: 'httpd'
