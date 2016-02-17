
# Network Restart

    module.exports = header: 'Network Restart', timeout: -1, handler: ->
      @execute
        cmd: 'service network restart'
