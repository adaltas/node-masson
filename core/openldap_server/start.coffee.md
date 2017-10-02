
# OpenLDAP Server Start

Start the slapd daemon.

    module.exports = header: 'OpenLDAP Server Start', handler: ->
      @service.start
        name: 'slapd'
