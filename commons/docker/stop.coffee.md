
# Docker Stop

Stop the Docker daemon.

    module.exports = header: 'Docker Stop', handler: (options) ->
      @service.stop name: 'docker'
