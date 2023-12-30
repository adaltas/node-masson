
# Bind Server Stop

Stop the "named" service.

    export default header: 'Bind Server Stop', handler: ->
      @service.stop name: 'named'
