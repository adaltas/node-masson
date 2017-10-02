
# Docker Start

Start the Docker daemon.

    module.exports = header: 'Docker Start', handler: (options) ->
      @service.start name: 'docker'
