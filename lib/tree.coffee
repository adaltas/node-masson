
crypto = require 'crypto'
util = require 'util'
{EventEmitter} = require 'events'
multimatch = require 'multimatch'
load = require './load'
{flatten} = require './misc'
Module = require 'module'

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
  @default_command = 'install'
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
  # Normalize Options
  options.modules = [options.modules] if typeof options.modules is 'string'
  options.modules = [] unless Array.isArray options.modules
  # Filter with the modules options
  if options.command and options.command isnt @default_command
    # All the modules declaring the command
    modules = []
    for name, filename of @cache
      module = Module._cache[filename]
      for middleware in module.exports
        if options.command in middleware.commands
          modules.push module
          break
    names = modules.map (m) -> m.name
  else
    names = @names
  # Return the list of all modules
  modules = @load_modules_for_command names, options.command
  # Filter by module
  if options.modules.length
    names = Object.keys modules
    names = multimatch names, options.modules
    # Re-compute modules to ensure correct ordering
    modules = @load_modules_for_command names, options.command
  middlewares = @load_middlewares modules
  if options.fast
    middlewares = middlewares.filter (middleware) =>
      return true if multimatch(middleware.module, options.modules).length
      middleware.required
  # only
  required_middlewares_count = 0
  only_middlewares = middlewares.filter (middleware) =>
    required_middlewares_count++ if middleware.required 
    middleware.required or middleware.only
  middlewares = only_middlewares if only_middlewares.length > required_middlewares_count
  callback null, middlewares

###
Return all the commands referenced by the modules.
###
Tree::commands = ->
  commands = {}
  commands[@default_command] = true
  for name, filename of @cache
    module = Module._cache[filename]
    for middleware in module.exports
      for command in middleware.commands
        commands[command] = true unless command in commands
  Object.keys commands

Tree::load_modules = (names) ->
  modules = {}
  load_modules = (names, parent) =>
    for name in names
      continue if modules[name]
      modules[name] = @load_module name, parent
      for middleware in modules[name]
        load_modules middleware.modules, middleware.module
  load_modules names
  modules

Tree::load_modules_for_command = (names, command) ->
  modules = {}
  load_modules = (names) =>
    for name in names
      continue if modules[name]?
      newmodule = []
      modules[name] = true
      for middleware in @load_module name
        continue if command and middleware.commands.length > 0 and command not in middleware.commands
        load_modules middleware.modules 
        newmodule.push middleware
      modules[name] = newmodule
  load_modules names
  modules

Tree::load_middlewares = (modules) ->
  middlewares = []
  called = {}
  load_module = (name, handers) =>
    return if called[name]
    called[name] = true
    for middleware in handers
      for child in middleware.modules
        load_module child, modules[child] or @modules[child]
      middlewares.push middleware if middleware.handler
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
  return Module._cache[@cache[module]].exports if @cache[module]
  # Load the module
  required = false
  [_, meta, module] = /([\!\?]?)(.*)/.exec module
  switch meta
    when '?' then # nothing yet
    when '!' then required = true
  # Load the module
  m = load module, parent
  m.name = module
  m.parents ?= []
  m.parents.push parent
  m.exports = [m.exports] unless Array.isArray m.exports
  for middleware, i in m.exports
    throw Error "Module '#{module}' export an undefined middleware" unless middleware?
    middleware = m.exports[i] = handler: middleware if typeof middleware is 'function'
    middleware = m.exports[i] = modules: middleware if typeof middleware is 'string'
    middleware.filename ?= m.filename
    middleware.module ?= module
    middleware.id ?= "#{module}/#{i}"
    middleware.name ?= null
    middleware.index ?= i
    middleware.commands ?= []
    middleware.commands = [middleware.commands] unless Array.isArray middleware.commands
    middleware.modules ?= []
    middleware.modules = [middleware.modules] unless Array.isArray middleware.modules
    if typeof middleware.handler is 'string'
      middleware.modules.push middleware.handler 
      middleware.handler = null
    middleware.skip ?= false
    middleware.required = true if required
    middleware.module = module
  @cache[module] = m.filename
  m.exports

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
