
# OpenLDAP Client Wait

    export default header: 'OpenLDAP Client Wait', handler: ({options}) ->

      @connection.wait
        header: 'TCP'
        servers: options.tcp
