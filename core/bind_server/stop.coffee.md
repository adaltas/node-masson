
# Bind server

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Stop

Now the service being configured, the "named" service is started.

    exports.push name: 'Bind Server # Stop', label_true: 'STOPPED', handler: ->
      @service_stop name: 'named'
