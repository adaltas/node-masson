
# HTTPD Web Server Check

Check the health of the HTTPD service.

Note, we've seen case where the status command print "httpd dead but subsys
locked".

    module.exports = header: 'HTTPD Check', label_true: 'CHECKED', handler: ->
      @system.execute
        header: 'TCP 80'
        cmd: "echo > /dev/tcp/#{@config.host}/80"
