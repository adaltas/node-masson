# PostgreSQL Configure

    module.exports = handler: ->
      postgres = @config.postgres ?= {}
      # docker image version
      postgres.version ?= '9.5'
      server = postgres.server ?= {}
      server.password ?= 'root'
      server.user ?= 'root'
      server.port ?= '5432'
      postgres.container_name ?= 'postgres_server'
