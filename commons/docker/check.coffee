
export default header: 'Docker Check', handler: ({options}) ->
  # Runing Sevrice
  # Ensure the "ntpd" service is up and running.
  @service.assert
    header: 'Service'
    name: options.yum_name
    srv_name: options.srv_name
    installed: true
    started: true
