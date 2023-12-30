
# Bind Server Start

Start the "named" service.

    export default header: 'Bind Server Start', handler: ->
      @service.start name: 'named'
