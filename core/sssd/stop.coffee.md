
# SSSD Stop

    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push name: 'SSSD # Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'sssd'
