
# PostgreSQL Server Stop

PostgreSQL Server is started through service command.Which is wrapper around 
the docker container.

    module.exports = header: 'PostgreSQL Server Stop', label_true: 'STARTED', handler: ->
      @service_stop
        name: 'postgres-server'
