
# SSSD Start

    export default header: 'SSSD Start', handler: ->
      @service.start
        name: 'sssd'
