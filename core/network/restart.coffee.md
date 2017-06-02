
# Network Restart

    module.exports = header: 'Network Restart', handler: ->
      @system.execute
        cmd: 'service network restart'
