
# PostgreSQL Server Configure

    module.exports = ->
      options = @config.postgres ?= {}
      
      # docker image version
      options.version ?= '9.5'
      options.server ?= {}
      options.server.password ?= 'root'
      options.server.user ?= 'root'
      options.server.port ?= '5432'
      options.server.container_name ?= 'postgres_server'
