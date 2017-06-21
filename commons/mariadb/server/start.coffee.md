
# MariaDB Server Start

    module.exports = header: 'MariaDB Server Start', handler: ->
      @service.start 'mariadb'
