
# Iptables Status

Print the status for the Iptables service.

    module.exports = header: 'Iptables Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'iptables'
        if_exists: '/etc/init.d/iptables'
