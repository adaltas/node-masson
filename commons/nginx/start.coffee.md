
# NGINX Web Server Start

Start the NGINX service

    export default header: 'NGINX Start', handler: ->
      @service.start name: 'nginx'
