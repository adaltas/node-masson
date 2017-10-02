
# OpenLDAP Client Wait

    module.exports = header: 'OpenLDAP Client Wait', handler: (options) ->

      @connection.wait
        header: 'TCP'
        servers: options.tcp
