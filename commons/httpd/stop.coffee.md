
# HTTPD Web Server Stop

Start the HTTPD service by executing the command `service httpd stop`.

    module.exports = header: 'HTTPD # Stop', label_true: 'STOPPED', handler: ->
      @service_stop name: 'httpd'
