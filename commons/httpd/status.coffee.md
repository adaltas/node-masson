
# HTTPD Web Server Status

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Status

Princ the status for the HTTPD service by executing the command
`service httpd status`.

    exports.push name: 'HTTPD # Status', handler: (ctx, next) ->
      ctx.execute
        cmd: "service httpd status"
        code_skipped: 3
      , (err, started) ->
        next err, if started then 'STARTED' else 'STOPPED'