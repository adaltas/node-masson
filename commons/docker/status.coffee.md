
# Docker Status

Print the status of the docker daemon.

    module.exports = header: 'Docker Status', handler: (options) ->
      @service.status
        name: 'docker'
        if_exists: '/etc/init.d/docker'
