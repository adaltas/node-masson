
export default header: 'PostgreSQL Server Start', handler: ->
  @service.start
    name: 'postgres-server'
