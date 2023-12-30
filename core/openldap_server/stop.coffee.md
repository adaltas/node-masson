
# OpenLDAP Server Start

Stop the slapd daemon.

    export default header: 'OpenLDAP Server Stop', handler: ->
      @service.stop
        name: 'slapd'
