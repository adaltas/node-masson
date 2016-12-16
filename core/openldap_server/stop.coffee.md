
# OpenLDAP Server Start

Stop the slapd daemon.

    module.exports = header: 'OpenLDAP Server Stop', label_true: 'STOPPED', handler: ->
      @service.start
        name: 'slapd'
