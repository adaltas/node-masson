
# MySQL Server Wait

    export default header: 'MySQL Server Wait', handler: (options) ->
    
      throw Error "Required Options: fqdn" unless options.fqdn
      throw Error "Required Options: port" unless options.port

## Wait TCP

      @connection.wait
        header: 'TCP'
        host: options.fqdn
        port: options.port
