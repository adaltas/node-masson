
# Bind server Stop

Stop the "named" service.

    module.exports = header: 'Bind Server # Stop', label_true: 'STOPPED', handler: ->
      @service_stop name: 'named'
