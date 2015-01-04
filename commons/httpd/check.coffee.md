
# HTTPD Web Server Check

    module.exports = []

## Check

Check the health of the HTTPD service.

Note, we've seen case where the status command print "httpd dead but subsys
locked".

    module.exports.push name: 'HTTPD # Check Status', callback: (ctx, next) ->
      ctx.execute
        cmd: "service httpd status"
      , next