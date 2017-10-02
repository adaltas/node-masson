
# Iptables Stop

Start the Iptables service by executing the command `service iptables stop`.

    module.exports = header: 'Iptables Stop', handler: ->
      @service.stop name: 'iptables'
