
# Iptables Start

Start the Iptables service by executing the command `service iptables start`.

    module.exports = header: 'Iptables Start', handler: ->
      @service.start
        if: @config.iptables.action is 'start'
        name: 'iptables'
