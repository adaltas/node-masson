
# Bind server Start

Start the "named" service.

    module.exports = header: 'Bind Server # Start', label_true: 'STARTED', handler: ->
      @service_start name: 'named'
