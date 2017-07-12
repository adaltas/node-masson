
# Docker Stop

Stop the Docker daemon.

    module.exports = header: 'Docker Stop', label_true: 'STOPPED', handler: (options) ->
      @service.stop name: 'docker'
