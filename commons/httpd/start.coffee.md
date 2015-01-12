
# HTTPD Web Server Start

    exports = module.exports = []

## Start

Start the HTTPD service by executing the command `service httpd start`.

    exports.push name: 'HTTPD # Start', callback: (ctx, next) ->
      {action} = ctx.config.httpd
      ctx.service srv_name: 'httpd', action: action, next