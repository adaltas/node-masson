
# SSSD Stop

    export default header: 'SSSD Stop', handler: ->
      @service.stop
        name: 'sssd'
