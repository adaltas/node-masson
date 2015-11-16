
# Network Restart

    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push header: 'Network # Restart', timeout: -1, handler: ->
      @execute
        cmd: 'service network restart'
