
# HTTPD Web Server Status

    exports = module.exports = []

## Status

Princ the status for the HTTPD service by executing the command
`service httpd status`.

    exports.push name: 'HTTPD # Status', callback: (ctx, next) ->
      ctx.execute
        cmd: "service httpd status"
        code_skipped: 3
      , (err, started) ->
        next err, if started then 'STARTED' else 'STOPPED'