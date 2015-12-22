
# HTTPD Web Server Check

    exports = module.exports = []
    exports.push 'masson/commons/httpd/status'

## Check

Check the health of the HTTPD service.

Note, we've seen case where the status command print "httpd dead but subsys
locked".

    exports.push header: 'HTTPD # Check TCP', label_true: 'CHECKED', handler: ->
      @execute cmd: "echo > /dev/tcp/#{@config.host}/80"
