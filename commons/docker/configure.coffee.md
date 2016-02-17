
# Docker Configure

    module.exports = handler: ->
      @config.docker ?= {}
      @config.docker.nsenter ?= true
