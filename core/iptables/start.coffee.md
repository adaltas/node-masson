
# Iptables Start

Start the Iptables service by executing the command `service iptables start`.

    module.exports = header: 'Iptables Start', label_true: 'STARTED', handler: ->
      @service_start 
        if: @config.iptables.action is 'start'
        name: 'iptables'
