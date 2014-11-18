
crypto = require 'crypto'
util = require 'util'
{EventEmitter} = require 'events'
multimatch = require 'multimatch'
load = require './load'
{flatten} = require './misc'

###
Tree
====

Build a tree with all the actions to execute from a list of modules.

Action properties:

-   `hidden`  Visibility of the action name
-   `name`    Name of the action
-   `module`  Module where the action is defined
-   `index`   Position of the action inside the module

Example using a callback

    tree = require './tree'
    tree modules, (err, actions) ->
      util.print actions

Example using the EventEmitter API:

    tree.actions(modules, options)
    .on 'module', (location) ->
      util.print 'module', location
    .on 'action', (action) ->
      util.print 'action', action
    .on 'end', (actions) ->
      util.print actions
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
Tree::actions = (options, callback) ->
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
  actions = @load_actions modules
  if options.fast
    actions = actions.filter (action) =>
      return true if multimatch(action.module, options.modules).length
      action.required
  callback null, actions

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

Tree::load_actions = (modules) ->
  actions = []
  called = {}
  load_module = (name, handlers) =>
    return if called[name]
    called[name] = true
    for handler in handlers
      for child in handler.modules
        load_module child, modules[child] or @modules[child]
      actions.push handler if handler.callback
  for name, module of modules
    load_module name, module
  actions

###
Load a module and return its actions.

Module actions when defining a string dependency may be prefixed with:  

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
  actions = load module, parent
  actions = [actions] unless Array.isArray actions
  for callback, i in actions
    # Module dependencies
    # continue if typeof callback is 'string'
    throw Error "Module '#{module}' export an undefined action" unless callback?
    callback = actions[i] = callback: callback if typeof callback is 'function'
    callback = actions[i] = modules: callback if typeof callback is 'string'
    callback.commands ?= []
    callback.commands = [callback.commands] unless Array.isArray callback.commands
    callback.modules ?= []
    callback.modules = [callback.modules] unless Array.isArray callback.modules
    if typeof callback.callback is 'string'
      callback.modules.push callback.callback 
      callback.callback = null
    callback.id ?= "#{module}/#{i}"
    callback.name ?= null
    callback.module ?= module
    callback.index ?= i
    callback.skip ?= false
    callback.required = true if required
  @cache[module] = actions

module.exports = (modules, options, callback)->
  new Tree modules
module.exports.Tree = Tree
