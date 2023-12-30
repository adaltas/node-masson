
# MySQL Server Stop

    export default header: 'MySQL Server Stop', handler: ->
      @service.start 'mysqld'
