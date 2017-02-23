
# Network Restart

    module.exports = header: 'Network Restart', timeout: -1, handler: ->
      @system.execute
        cmd: 'service network restart'
