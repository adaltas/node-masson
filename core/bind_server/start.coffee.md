
# Bind Server Start

Start the "named" service.

    module.exports = header: 'Bind Server Start', handler: ->
      @service.start name: 'named'
