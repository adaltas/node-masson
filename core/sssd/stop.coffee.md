
# SSSD Stop

    module.exports = header: 'SSSD # Stop', label_true: 'STOPPED', handler: ->
      @service.stop
        name: 'sssd'
