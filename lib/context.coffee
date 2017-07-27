
nikita = require 'nikita'

module.exports = (contexts, params, services, config) ->
  config.nikita ?= {}
  config.nikita.no_ssh = true
  m = nikita config.nikita
  m.params = params
  m.config = config
  m.services = services
  m.contexts = (services) ->
    services = [services] if typeof services is 'string'
    throw Error 'Invalid argument to context.contexts' unless Array.isArray services
    contexts.filter (context) ->
      for service in services
        for ctx_service in context.services
          return true if minimatch ctx_service, service
      return false
  m.has_service = (services...) ->
    # service = [service] if typeof service is 'string'
    services = misc.array.flatten services
    services.some (srv) =>
      m.services.indexOf(srv) isnt -1
  m

misc = require 'nikita/lib/misc'
minimatch = require 'minimatch'
