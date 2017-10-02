
# Iptables Status

Print the status for the Iptables service.

    module.exports = header: 'Iptables Status', handler: ->
      @service.status
        name: 'iptables'
