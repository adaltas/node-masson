
# SSSD Stop

    module.exports = header: 'SSSD # Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'sssd'
