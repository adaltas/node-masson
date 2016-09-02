
# OpenLDAP Server Start

Start the slapd daemon.

    module.exports = header: 'OpenLDAP Server Start', label_true: 'STARTED', handler: ->
      @service.start
        name: 'slapd'
