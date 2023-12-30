
export default header: 'Docker Stop', handler: (options) ->
  @service.stop name: 'docker'
