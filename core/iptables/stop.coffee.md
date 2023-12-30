
# Iptables Stop

Start the Iptables service by executing the command `service iptables stop`.

    export default header: 'Iptables Stop', handler: ->
      @service.stop name: 'iptables'
