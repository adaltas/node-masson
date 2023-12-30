
export default header: 'Docker Status', handler: (options) ->
  @service.status
    name: 'docker'
    if_exists: '/etc/init.d/docker'
