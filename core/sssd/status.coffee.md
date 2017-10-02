
# SSSD Status

    module.exports = header: 'SSSD Status', handler: ->
      @service.status name: 'sssd'
