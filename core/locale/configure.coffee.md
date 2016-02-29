
# Users Locale Configure

    module.exports = handler: ->
      @config.locale ?= {}
      @config.locale.lang ?= 'en_US.UTF-8'
