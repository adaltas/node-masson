
# NGINX Web Server Stop

Start the NGINX Web Server service.

    export default header: 'NGINX Stop', handler: ->
      @service.stop name: 'nginx'
