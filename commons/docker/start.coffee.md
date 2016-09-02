
# Docker Start

Start the Docker daemon.

    module.exports = header: 'Docker Start', label_true: 'STARTED', handler: ->
      @service.start name: 'docker'
