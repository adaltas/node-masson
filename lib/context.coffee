
mecano = require 'mecano'

module.exports = (contexts, params, services, config) ->
  m = mecano config.mecano
  m.params = params
  m.config = config
  m.services = services
  m.contexts = (services) ->
    services = [services] if typeof services is 'string'
    throw Error 'Invalid argument to context.contexts' unless Array.isArray services
    contexts.filter (context) ->
      for service in services
        return true if service in context.services
  m.has_service = (services...) ->
    # service = [service] if typeof service is 'string'
    services = misc.array.flatten services
    services.some (srv) =>
      m.services.indexOf(srv) isnt -1
  m

misc = require 'mecano/lib/misc'
