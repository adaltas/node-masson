
# Bind Server Check

Check the health of the Bind server.

    export default header: 'Bind Server Check', handler: ->

## Runing Sevrice

Ensure the "named" service is up and running.

      @service.assert
        header: 'Service'
        name: 'bind'
        srv_name: 'named'
        installed: true
        started: true
