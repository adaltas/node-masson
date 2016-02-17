
# Iptables Stop

Start the Iptables service by executing the command `service iptables stop`.

    module.exports = header: 'Iptables # Stop', label_true: 'STOPPED', handler: ->
      @service_stop name: 'iptables'
