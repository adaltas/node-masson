
# OpenLDAP Server Start

Stop the slapd daemon.

    module.exports = header: 'OpenLDAP Server Stop', handler: ->
      @service.stop
        name: 'slapd'
