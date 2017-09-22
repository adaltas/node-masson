
# Mysql client configuration

    module.exports = (service) ->
      service = migration.call @, service, 'masson/commons/mysql/client', ['mysql', 'client'], require('nikita/lib/misc').merge require('.').use,
        mysql_server: key: ['mysql', 'server']
      @config.mysql ?= {}
      options = @config.mysql.client = service.options

## Repository

      options.repo ?= service.use.mysql_server.options.repo

## Dependencies

    migration = require '../../../lib/migration'
      
