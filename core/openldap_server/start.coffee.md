
# OpenLDAP Server Start

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Start

    exports.push name: 'OpenLDAP Server # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'slapd'
