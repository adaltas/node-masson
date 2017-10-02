
# Bind Server Stop

Stop the "named" service.

    module.exports = header: 'Bind Server Stop', handler: ->
      @service.stop name: 'named'
