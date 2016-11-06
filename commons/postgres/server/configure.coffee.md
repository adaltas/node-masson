# PostgreSQL Configure

    module.exports = ->
      postgres = @config.postgres ?= {}
      # docker image version
      postgres.version ?= '9.5'
      postgres.server ?= {}
      postgres.server.password ?= 'root'
      postgres.server.user ?= 'root'
      postgres.server.port ?= '5432'
      postgres.server.container_name ?= 'postgres_server'
