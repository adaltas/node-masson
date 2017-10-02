
# NGINX Web Server Stop

Start the NGINX Web Server service.

    module.exports = header: 'NGINX Stop', handler: ->
      @service.stop name: 'nginx'
