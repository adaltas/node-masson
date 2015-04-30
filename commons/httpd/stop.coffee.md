
# HTTPD Web Server Stop

    exports = module.exports = []

## Stop

Start the HTTPD service by executing the command `service httpd stop`.

    exports.push name: 'HTTPD # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'httpd'
        action: 'stop'
      , next
