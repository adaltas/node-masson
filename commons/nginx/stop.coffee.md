
# NGINX Web Server Stop

Start the NGINX Web Server service.

    module.exports = header: 'NGINX Stop', label_true: 'STOPPED', handler: ->
      @service.stop name: 'nginx'
