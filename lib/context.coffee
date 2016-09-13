
mecano = require 'mecano'
{EventEmitter} = require 'events'
{flatten, merge} = require './misc'

class Context extends EventEmitter
  constructor: (contexts, @params, @config)->
    # delete @config.servers
    @_contexts = contexts
    options = {}
    # options.cache = true
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
  has_all_modules: (modules...) ->
    modules = flatten modules
    for module in modules
      return false unless @has_module module
    return true
  has_any_modules: (modules...) ->
    has_module = []
    modules = flatten modules
    for module in modules
      has_module.push module if @has_module module
    return if has_module.length then has_module else false

module.exports = (contexts, params, config) ->
  return new Context contexts, params, config
module.exports.Context = Context
