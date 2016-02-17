
# SSSD Start

    module.exports = header: 'SSSD # Start', handler: ->
      @service_start
        name: 'sssd'
