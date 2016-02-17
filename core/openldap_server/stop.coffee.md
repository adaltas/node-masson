
# OpenLDAP Server Start

Stop the slapd daemon.

    module.exports = header: 'OpenLDAP Server # Stop', label_true: 'STOPPED', handler: ->
      @service_start
        name: 'slapd'
