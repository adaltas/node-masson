
# Mysql client configuration

    module.exports = ->
      [my_srv_ctx] = @contexts 'masson/commons/mysql/server'
      @config.mysql ?= {}
      options = @config.mysql.client ?= {}

## Repository

      options.repo ?= my_srv_ctx.config.mysql.server.repo
      
