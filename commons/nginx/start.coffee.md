
# NGINX Web Server Start

Start the NGINX service

    module.exports = header: 'NGINX Start', handler: ->
      @service.start name: 'nginx'
