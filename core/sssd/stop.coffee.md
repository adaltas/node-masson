
# SSSD Stop

    module.exports = header: 'SSSD Stop', handler: ->
      @service.stop
        name: 'sssd'
