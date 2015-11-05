
# OpenLDAP Server Start

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Stop

    exports.push header: 'OpenLDAP Server # Stop', label_true: 'STOPPED', handler: ->
      @service_start
        name: 'slapd'
