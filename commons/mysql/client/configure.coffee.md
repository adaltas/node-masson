
# Mysql client configuration

    module.exports = ->
      service = migration.call @, service, 'masson/commons/mysql/client', ['mysql', 'client'], require('nikita/lib/misc').merge require('.').use,
        mysql_server: key: ['mysql', 'server']
      options = @config.mysql = service.options

## Repository

      options.repo ?= service.use.mysql_server.options.repo
      
