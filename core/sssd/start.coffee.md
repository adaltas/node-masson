
# SSSD Start

    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push name: 'SSSD # Start', handler: ->
      @service_start
        name: 'sssd'
