
# MySQL Server Stop

    module.exports = header: 'MySQL Server Stop', handler: ->
      @service.start 'mysqld'
