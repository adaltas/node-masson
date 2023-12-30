
# Iptables Status

Print the status for the Iptables service.

    export default header: 'Iptables Status', handler: ->
      @service.status
        name: 'iptables'
