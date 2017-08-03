
# Bind Server Start

Start the "named" service.

    module.exports = header: 'Bind Server Start', label_true: 'STARTED', handler: ->
      @service.start name: 'named'
