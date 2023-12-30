
export default header: 'PostgreSQL Server Stop', handler: ->
  @service.stop
    name: 'postgres-server'
