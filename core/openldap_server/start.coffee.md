
# OpenLDAP Server Start

Start the slapd daemon.

    export default header: 'OpenLDAP Server Start', handler: ->
      @service.start
        name: 'slapd'
