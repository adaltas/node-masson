
crypto = require 'crypto'
util = require 'util'
{EventEmitter} = require 'events'
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
Tree = (modules, options) ->
  @
util.inherits Tree, EventEmitter

###
Build a run list for the given modules.   

Options include:   

-   `modules` Only return this module and its dependencies   
-   `fast`    Skip dependencies   
-   `all`     Return the full list of actions, work with the `module` and `fast` options   

###
Tree::actions = (modules, options, callback) ->
  if typeof options is 'function'
    callback = options
    options = {}
  options.modules = [options.modules] if typeof options.modules is 'string'
  options.modules = [] unless Array.isArray options.modules
  ev = new EventEmitter
  setImmediate =>
    modules = [modules] unless Array.isArray modules
    modules = flatten modules
    # Declare bootstrap as a required dependecies
    modules.unshift 'phyla/bootstrap'
    # Buil a full tree
    try tree = @load_tree modules
    catch err
      ev.emit 'error', err
      callback err
      return
    # Filter with the modules options
    if options.modules.length
      modules = tree.map (leaf) -> leaf.module
      modules = options.modules.filter (module) -> modules.indexOf(module) isnt -1
      modules.unshift 'phyla/bootstrap' if modules.length
      tree = @load_tree modules
      # Filter with the fast options
      tree = tree.filter( (leaf) => 
        leaf.module.indexOf('phyla/bootstrap') is 0 or 
        options.modules.indexOf(leaf.module) isnt -1
      ) if options.fast
    # Emit event and return actions
    actions = []
    for leaf in tree
      ev.emit 'module', leaf.module
      for action in leaf.actions
        ev.emit 'action', action
        actions.push action
    ev.emit 'end', actions
    callback null, actions if callback
  ev

Tree::modules = (modules, options, callback) ->
  mods = []
  @actions(modules, options)
  .on 'module', (module) ->
    mods.push module
  .on 'error', (err) ->
    callback err
  .on 'end', ->
    callback null, mods

###
Return a array of object with the module name and its associated actions
###
Tree::load_tree = (modules) ->
  called = {}
  tree = []
  build_tree = (module) =>
    return if called[module]
    called[module] = true
    leaf = module: module, actions: []
    for action in @load_module module
      if typeof action is 'string'
        build_tree action
      else
        leaf.actions.push action
    tree.push leaf
  for module in modules then build_tree module
  tree

###
Load a module and return its actions
###
Tree::load_module = (module) ->
  @cache ?= {}
  return @cache[module] if @cache[module]
  @cache[module] = actions = []
  # Load the module
  callbacks = load module
  callbacks = [callbacks] unless Array.isArray callbacks
  for callback, i in callbacks
    # Module dependencies
    if typeof callback is 'string'
      actions.push callback
      continue
    callback = callback: callback if typeof callback is 'function'
    callback.hidden ?= true unless callback.name
    callback.name ?= "#{module}/#{i}"
    callback.module ?= module
    callback.index ?= i
    callback.skip = false
    callback.required = true if module.indexOf('phyla/bootstrap') is 0
    actions.push callback
  actions

module.exports = (modules, options, callback)->
  (new Tree).actions modules, options, callback
module.exports.Tree = Tree
