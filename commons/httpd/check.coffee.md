
# HTTPD Web Server Check

Check the health of the HTTPD service.

Note, we've seen case where the status command print "httpd dead but subsys
locked".

    module.exports = header: 'HTTPD Check', handler: (options) ->

## Runing Sevrice

Ensure the "ntpd" service is up and running.

      @service.assert
        header: 'Service'
        name: 'httpd'
        installed: true
        started: true

## TCP Connection

Ensure the port is listening.

      @connection.assert
        header: 'TCP'
        host: options.wait_tcp.fqdn
        port: options.wait_tcp.port
