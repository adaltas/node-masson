
# SSSD Start

    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push header: 'SSSD # Start', handler: ->
      @service_start
        name: 'sssd'
