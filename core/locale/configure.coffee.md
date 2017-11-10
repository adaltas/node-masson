
# Users Locale Configure

    module.exports = (service) ->
      options = service.options

      options.users = service.deps.system.options.users
      options.lang ?= 'en_US.UTF-8'
