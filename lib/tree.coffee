
crypto = require 'crypto'
util = require 'util'
{EventEmitter} = require 'events'
multimatch = require 'multimatch'
load = require './load'
{flatten} = require './misc'

###
Tree
====

Build a tree with all the middlewares to execute from a list of modules.

Middleware properties:

-   `hidden`  Visibility of the middleware name
-   `name`    Name of the middleware
-   `module`  Module where the middleware is defined
-   `index`   Position of the middleware inside the module

Example returning middlewares

    tree = require './tree'
    tree(modules).middlewares, (err, middlewares) ->
      util.print middlewares

Example using the EventEmitter API:

    tree(modules).middlewares(command, options)
    .on 'module', (location) ->
      util.print 'module', location
    .on 'action', (middleware) ->
      util.print 'middleware', middleware
    .on 'end', (middlewares) ->
      util.print middlewares
    .on 'error', (err) ->
      util.print err 
###
Tree = (modules) ->
  modules = [modules] unless Array.isArray modules
  modules = flatten modules
  @names = modules
  @modules = @load_modules modules
  @
util.inherits Tree, EventEmitter

###
Build a run list for the given modules.   

Options include:   

-   `command` Filter modules for a particular command
-   `modules` Only return this module and its dependencies   
-   `fast`    Skip dependencies    

###
Tree::middlewares = (options, callback) ->
  if typeof options is 'function'
    callback = options
    options = {}
  options.modules = [options.modules] if typeof options.modules is 'string'
  options.modules = [] unless Array.isArray options.modules
  modules = @modules
  # Filter with the modules options
  if options.command and options.command isnt 'install'
    parentmodules = {}
    childmodules = []
    for name, module of modules
      filteredhandlers = []
      for handler in module
        if options.command in handler.commands
          filteredhandlers.push handler
          for child in handler.modules
            childmodules.push child
          # break
      if filteredhandlers.length
        parentmodules[name] = filteredhandlers
    childmodules = @load_modules childmodules
    newmodules = {}
    for name, module of parentmodules
      newmodules[name] = module
    for name, module of childmodules
      newmodules[name] = module
    modules = newmodules
  else if options.command
    modules = @load_modules_install @names
    # for name in @names
    #   module = modules[name]
    #   for handler in module
    #     if options.command in handler.commands or handler.commands.length is 0

    # console.log modules
    # console.log Object.keys modules
    # process.exit()
  if options.modules.length
    names = Object.keys modules
    names = multimatch names, options.modules
    newmodules = {}
    for name in names
      newmodules[name] = modules[name]
    modules = newmodules
  middlewares = @load_middlewares modules
  if options.fast
    middlewares = middlewares.filter (middleware) =>
      return true if multimatch(middleware.module, options.modules).length
      middleware.required
  callback null, middlewares

Tree::load_modules = (names) ->
  modules = {}
  load_modules = (names) =>
    for name in names
      continue if modules[name]
      modules[name] = @load_module name
      for handler in modules[name]
        load_modules handler.modules
  load_modules names
  modules

Tree::load_modules_install = (names) ->
  modules = {}
  load_modules = (names) =>
    for name in names
      continue if modules[name]?
      newmodule = []
      modules[name] = true
      for handler in @load_module name
        continue if handler.commands.length > 0 and 'install' not in handler.commands
        load_modules handler.modules 
        newmodule.push handler
      modules[name] = newmodule
  load_modules names
  modules

Tree::load_middlewares = (modules) ->
  middlewares = []
  called = {}
  load_module = (name, handlers) =>
    return if called[name]
    called[name] = true
    for handler in handlers
      for child in handler.modules
        load_module child, modules[child] or @modules[child]
      middlewares.push handler if handler.handler
  for name, module of modules
    load_module name, module
  middlewares

###
Load a module and return its middlewares.

Module middlewares when defining a string dependency may be prefixed with:  

*   "?": Load this module only if it is defined by the user in the run list.
*   "!": Force this module to be loaded and executed, apply to "fast" mode.

###
Tree::load_module = (module, parent) ->
  @cache ?= {}
  return @cache[module] if @cache[module]
  # Load the module
  required = false
  [_, meta, module] = /([\!\?]?)(.*)/.exec module
  switch meta
    when '?' then # nothing yet
    when '!' then required = true
  # Load the module
  m = load module, parent
  m.exports = [m.exports] unless Array.isArray m.exports
  for middleware, i in m.exports
    # Module dependencies
    # continue if typeof middleware is 'string'
    throw Error "Module '#{module}' export an undefined middleware" unless middleware?
    middleware = m.exports[i] = handler: middleware if typeof middleware is 'function'
    middleware = m.exports[i] = modules: middleware if typeof middleware is 'string'
    middleware.filename = m.filename
    middleware.commands ?= []
    middleware.commands = [middleware.commands] unless Array.isArray middleware.commands
    middleware.modules ?= []
    middleware.modules = [middleware.modules] unless Array.isArray middleware.modules
    if typeof middleware.handler is 'string'
      middleware.modules.push middleware.handler 
      middleware.handler = null
    middleware.id ?= "#{module}/#{i}"
    middleware.name ?= null
    middleware.module ?= module
    middleware.index ?= i
    middleware.skip ?= false
    middleware.required = true if required
  @cache[module] = m.exports

###

Retrieve all modules:

```coffee
tree = require('tree')
tree(modules, options).modules options, (err, modules) ->
  console.log modules
```

Retrieve all middlewares:

```coffee
tree = require('tree')
tree(modules, options).middlewares command: 'install', (err, modules, middlewares) ->
  console.log modules, middlewares
```
###
module.exports = (modules, options) ->
  new Tree modules
module.exports.Tree = Tree
