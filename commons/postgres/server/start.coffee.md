
# PostgreSQL Server Start

PostgreSQL Server is started through service command.Which is wrapper around 
the docker container.

    module.exports = header: 'PostgreSQL Server Start', handler: ->
      @service.start
        name: 'postgres-server'
