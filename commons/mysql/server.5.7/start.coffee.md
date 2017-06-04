
# MySQL Server Start

    module.exports = header: 'MySQL Server Start', handler: ->
      @service.start 'mysqld'
