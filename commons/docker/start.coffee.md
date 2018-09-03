
# Docker Start

Start the Docker daemon.

    module.exports = header: 'Docker Start', handler: ->
      @service.start name: 'docker'
