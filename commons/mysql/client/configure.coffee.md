
# Mysql client configuration

    export default (service) ->
      options = service.options

## Repository

      options.repo ?= service.deps.mysql_server.options.repo
