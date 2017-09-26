
# Users Locale Configure

    module.exports = (service) ->
      service = migration.call @, service, 'masson/core/locale', ['locale'], require('nikita/lib/misc').merge require('.').use,
        'system': key: ['system'] 
      options = @config.locale = service.options
      options = @config.locale ?= {}
      options.users = service.use.system.users
      options.lang ?= 'en_US.UTF-8'

## Dependencies

    migration = require '../../lib/migration'
