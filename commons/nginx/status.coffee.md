
# NGINX Web Server Status

Print the status for the NGINX Web Server service.

    module.exports = header: 'NGINX Status', handler: ->
      @service.status
        name: 'nginx'
        if_exists: '/etc/init.d/nginx'
