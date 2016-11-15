
mecano = require 'mecano'
{EventEmitter} = require 'events'
{flatten, merge} = require './misc'

class Context extends EventEmitter
  constructor: (contexts, @params, @config)->
    @_contexts = contexts
    options = {}
    options.store = {}
    options[k] = v for k, v of @config.mecano
    mecano @, options
    @services = []
    @
  contexts: (services, modules=[]) ->
    services = [services] if typeof services is 'string'
    throw Error 'Invalid argument to context.contexts' unless Array.isArray services
    @_contexts.filter (context) ->
      for service in services
        return true if service in context.services
  has_service: (service) ->
    @services.indexOf(service) isnt -1

module.exports = (contexts, params, config) ->
  return new Context contexts, params, config
module.exports.Context = Context
