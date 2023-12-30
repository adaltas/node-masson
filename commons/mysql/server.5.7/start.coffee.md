
# MySQL Server Start

    export default header: 'MySQL Server Start', handler: ->
      @service.start 'mysqld'
