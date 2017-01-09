
path = require 'path'
util = require 'util'
multimatch = require './multimatch'
each = require 'each'
{EventEmitter} = require 'events'
Module = require 'module'
{merge} = require 'mecano/lib/misc'

tsort = require 'tsort'
mecano = require 'mecano'
constraints = require './constraints'
context = require './context'

normalize_service = (service) ->
  service = require.main.require service if typeof service is 'string'
  service.use ?= {}
  for id, v of service.use
    v = service.use[id] = module: v if typeof v is 'string'
    v.id ?= v.module
  service.commands ?= {}
  service.config ?= {}
  service.config = merge {}, service.config... if Array.isArray service.config
  service.configure ?= []
  service.configure = [service.configure] unless Array.isArray service.configure
  service.constraints ?= {}
  service.constraints.tags ?= {}
  for k, v of service.constraints.tags
    service.constraints.tags[k] = "#{v}": true if typeof v in ['string', 'number']
    if Array.isArray service.constraints.tags[k]
      values = service.constraints.tags[k]
      service.constraints.tags[k] = {}
      service.constraints.tags[k][value] = true for value in values
  service.constraints.nodes ?= {}
  service.constraints.nodes = "#{service.constraints.nodes}": true if typeof service.constraints.nodes in ['string', 'number']
  if Array.isArray service.constraints.nodes
    nodes = service.constraints.nodes
    service.constraints.nodes = {}
    service.constraints.nodes[node] = true for node in nodes
  for command, v of service.commands
    v = service.commands[command] = handler: v if typeof v is 'string'
  service

Run = (params, @config) ->
  params.end ?= true
  EventEmitter.call @
  @setMaxListeners 100
  process.on 'uncaughtException', (err) =>
    @emit 'error', err
  @config.config = merge {}, @config.config... if Array.isArray @config.config
  # Normalize nodes
  for id, node of @config.nodes
    node.id ?= id
    node.config ?= {}
    node.config.host ?= id
    node.config.shortname ?= node.config.host.split('.')[0]
  # Discover module inside parent project
  for p in Module._nodeModulePaths path.resolve '.'
    require.main.paths.push p
  # Merge service configuration
  for id, service of @config.services
    service.id = id
    service.module ?= id
    normalize_service service
    merge service, normalize_service service.module
  # Add auto loaded services
  load_children = (service) =>
    for id, use of service.use
      if use.implicit
        module = @config.services[use.id] or require.main.require(use.module)
        use = merge module, use
        child = @config.services[use.id] = normalize_service use
        merge child.constraints, service.constraints
        load_children child
  for _, service of @config.services
    load_children service
  # Graph ordering
  graph = tsort()
  for _, service of @config.services
    graph.add service.id
    for id, use of service.use
      continue if use.id is service.id
      graph.add use.id, service.id
  service_ids = graph.sort()
  # Build Mecano context
  @contexts = []
  for id, node of @config.nodes
    @contexts.push context @contexts, params, merge {}, @config.config, node.config
  # List services in context
  for service_id in service_ids
    service = @config.services[service_id]
    continue unless service
    nodes = constraints @config.nodes, service.constraints
    nodes = nodes.map (node) -> node.config.host
    for context in @contexts
      context.services.push service_id if context.config.host in nodes
  # Merge service configuration into note
  for context in @contexts
    for service in context.services
      merge context.config, @config.services[service].config
  # Configuration
  for service_id in service_ids
    service = @config.services[service_id]
    continue unless service # Optional service
    for context in @contexts
      continue unless service_id in context.services
      for configure, i in service.configure
        switch typeof configure
          when 'string' then configure_fn = service.configure[i] = require.main.require configure
          when 'function' then configure_fn = configure
          else throw Error "Invalid configure defined by: #{JSON.stringify service_id}"
        try
          throw Error "Invalid configure module: #{JSON.stringify configure}" if typeof configure_fn.call isnt 'function'
          configure_fn.call context
        catch e
          console.log 'Catch error: ', e
          return
  @
util.inherits Run, EventEmitter

###
Options:
*   `command`
*   `hosts`
*   `modules`
###
Run::exec = (params='install') ->
  params = command: params if typeof params is 'string'
  services = @config.services
  each @contexts
  .parallel true
  .call (context, callback) ->
    return callback() if params.hosts and multimatch(context.config.host, params.hosts).length is 0
    error = false
    context.log.cli host: context.config.host, pad: host: 20, header: 60
    context.log.md basename: context.config.shortname
    context.ssh.open context.config.ssh, host: context.config.ip or context.config.host
    context.call ->
      for id in context.services then do (id) =>
        service = services[id]
        return if !service.required and params.modules and multimatch(service.module, params.modules).length is 0
        try
          if service.commands['']
            @call service.commands[''], (err) ->
              console.log 'ERROR', context.config.host, id, err if err
              error = true if err
          if service.commands[params.command] 
            @call service.commands[params.command], (err) ->
              console.log 'ERROR', context.config.host, id, err if err
              error = true if err
        catch err
          console.log 'ERROR', context.config.host, id, err if err
          error = true
          throw err
    context.then (err) ->
      @ssh.close()
      console.log 'ERROR', err if err and not error
      @then callback
  .then (err) =>
    @emit 'end'
  @

module.exports = (params, config) ->
  run = new Run params, config
  run
