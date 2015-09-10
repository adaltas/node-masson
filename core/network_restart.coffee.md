
    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push name: 'Network # restart', timeout: -1, handler: ->
      @execute
        cmd: 'service network restart'
