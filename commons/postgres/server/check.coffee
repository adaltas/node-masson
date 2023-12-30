
export default header: 'PostgreSQL Server Check', handler: (options) ->
  # TCP
  # Ensure the port is listening.
  @connection.assert
    header: 'TCP'
    host: options.wait_tcp.fqdn
    port: options.wait_tcp.port
