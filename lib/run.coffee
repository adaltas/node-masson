
path = require 'path'
util = require 'util'
multimatch = require './multimatch'
each = require 'each'
{EventEmitter} = require 'events'
{flatten, merge} = require './misc'
context = require './context'
Module = require 'module'
{merge} = require 'mecano/lib/misc'

tsort = require 'tsort'

###
The execution is done in 2 passes.

On the first pass, a context object is build for each server. A context is the 
same object inject to a middleware as first argument. In a context, other 
server contexts are available through the `hosts` object where keys are the 
server name. A context object is enriched with the "middlewares" and "modules" 
properties which are respectively a list of "middlewares" and a list of modules.

On the second pass, the middewares are executed.
###
Run = (params, config) ->
  params.end ?= true
  EventEmitter.call @
  @setMaxListeners 100
  process.on 'uncaughtException', (err) =>
    console.log 'masson/lib/run: uncaught exception'
    @emit 'error', err
  # Discover module inside parent project
  for p in Module._nodeModulePaths path.resolve '.'
    require.main.paths.push p
  each config.services
  .call (name, cluster, callback) ->
    cluster.name = name
    cluster.module ?= name
    cluster.use ?= {}
    # console.log cluster.module, require.main.require cluster.module
    merge cluster, require.main.require cluster.module
    callback()
  .then (err) ->
    return console.log 'err', err if err
    graph = tsort()
    for name, v of config.services
      for _, use of v.use
       graph.add use, name
    console.dir(graph.sort())
    # services = for _, v of config.services then v
    # services.sort (srva, srvb) ->
    #   # console.log srvb.use
    #   usea = for _, v of srva.use then v
    #   useb = for _, v of srvb.use then v
    #   code = 0
    #   if srva.name in useb then code = -1
    #   if srvb.name in usea then code = 1
    #   console.log srva.name, srvb.name, code
    #   code
    # # console.log services
    # services.map (service) ->
    #   console.log service.name
  @
util.inherits Run, EventEmitter

module.exports = (params, config) ->
  new Run params, config
