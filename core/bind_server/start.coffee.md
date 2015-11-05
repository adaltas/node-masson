
# Bind server

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Start

Now the service being configured, the "named" service is started.

    exports.push header: 'Bind Server # Start', label_true: 'STARTED', handler: ->
      @service_start name: 'named'
