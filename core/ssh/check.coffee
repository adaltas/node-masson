
export default header: 'SSH Check', handler: ->
  # Runing Sevrice
  # Ensure the "sshd" service is up and running.
  @service.assert
    header: 'Service'
    name: 'openssh-server'
    srv_name: 'sshd'
    installed: true
    started: true
