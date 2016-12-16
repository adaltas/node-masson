
# SSSD Start

    module.exports = header: 'SSSD Start', handler: ->
      @service.start
        name: 'sssd'
