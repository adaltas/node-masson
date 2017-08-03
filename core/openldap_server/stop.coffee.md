
# OpenLDAP Server Start

Stop the slapd daemon.

    module.exports = header: 'OpenLDAP Server Stop', label_true: 'STOPPED', handler: ->
      @service.stop
        name: 'slapd'
