
# Mysql Server Check

    module.exports = header: 'Mysql Server Check', handler: ->
      {mysql} = @config

## Wait Connect
Wait connect action is used as a check n the port availability.

      @connection.wait
        port: mysql.server.my_cnf['mysqld']['port']
        host: @config.host

## Dependencies

    db = require 'nikita/lib/misc/db'
