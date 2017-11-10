
# Mysql client configuration

    module.exports = (service) ->
      options = service.options

## Repository

      options.repo ?= service.deps.mysql_server.options.repo
