
# Docker Check

Check the health of the Docker daemon.

    module.exports = header: 'Docker Check', handler: (options) ->

## Runing Sevrice

Ensure the "ntpd" service is up and running.

      @service.assert
        header: 'Service'
        name: 'docker'
        installed: true
        started: true
