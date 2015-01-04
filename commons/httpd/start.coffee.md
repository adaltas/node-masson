
# HTTPD Web Server Start

    module.exports = []

## Start

Start the HTTPD service by executing the command `service httpd start`.

    module.exports.push name: 'HTTPD # Start', callback: (ctx, next) ->
      {action} = ctx.config.httpd
      ctx.service srv_name: 'httpd', action: action, next