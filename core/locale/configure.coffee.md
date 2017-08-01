
# Users Locale Configure

    module.exports = handler: ->
      options = @config.locale ?= {}
      options.lang ?= 'en_US.UTF-8'
