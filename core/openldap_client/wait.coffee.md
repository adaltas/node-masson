
# OpenLDAP Client Wait

    module.exports = header: 'OpenLDAP Client Wait', label_true: 'READY', handler: (options) ->

      @connection.wait
        header: 'TCP'
        servers: options.tcp
