
mecano = require 'mecano'

module.exports = (contexts, params, config) ->
  m = mecano config.mecano
  m.params = params
  m.config = config
  m.services = []
  m.contexts = (services) ->
    services = [services] if typeof services is 'string'
    throw Error 'Invalid argument to context.contexts' unless Array.isArray services
    contexts.filter (context) ->
      for service in services
        return true if service in context.services
  m.has_service = (service) ->
    @services.indexOf(service) isnt -1
  m
