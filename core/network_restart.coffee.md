
# Network Restart

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Restart

    exports.push name: 'Network # Restart', timeout: -1, handler: ->
      @execute
        cmd: 'service network restart'
