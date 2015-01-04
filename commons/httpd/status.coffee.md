
# HTTPD Web Server Status

    module.exports = []

## Status

Princ the status for the HTTPD service by executing the command
`service httpd status`.

    module.exports.push name: 'HTTPD # Status', callback: (ctx, next) ->
      ctx.execute
        cmd: "service httpd status"
        code_skipped: 3
      , (err, started) ->
        next err, if started then 'STARTED' else 'STOPPED'