
# NGINX Web Server Start

Start the NGINX service

    module.exports = header: 'NGINX Start', label_true: 'STARTED', handler: ->
      @service.start name: 'nginx'
