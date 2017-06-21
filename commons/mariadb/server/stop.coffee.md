
# MariaDB Server Stop

    module.exports = header: 'MariaDB Server Stop', handler: ->
      @service.stop 'mariadb'
