
# SSH Check

Check the health of the SSH server.

    module.exports = header: 'SSH Check', handler: ->

## Runing Sevrice

Ensure the "sshd" service is up and running.

      @service.assert
        header: 'Service'
        name: 'openssh-server'
        srv_name: 'sshd'
        installed: true
        started: true
