
# Docker Status

Print the status of the docker daemon.

    module.exports = header: 'Docker Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'docker'
        if_exists: '/etc/init.d/docker'
