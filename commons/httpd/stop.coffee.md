
# HTTPD Web Server Stop

    module.exports = []

## Stop

Start the HTTPD service by executing the command `service httpd stop`.

    module.exports.push name: 'HTTPD # Stop', callback: (ctx, next) ->
      ctx.service srv_name: 'httpd', action: 'stop', next