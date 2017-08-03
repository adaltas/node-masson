
# Cgroups Configure

The module accept the following properties:

## Source code

    module.exports = ->
      service = migration.call @, service, 'masson/core/cgroups', ['cgroups'], {}
      options = @config.cgroups = service.options

      options.groups ?= {}

## Dependencies

    migration = require '../../lib/migration'
