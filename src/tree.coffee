
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
      tree = @load_tree modules
      # Filter with the fast options
      tree = tree.filter( (leaf) => 
        return true if options.modules.indexOf(leaf.module) isnt -1
        leaf.actions = leaf.actions.filter (action) =>
          action.required
        leaf.actions.length
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
        # Split the current module actions in two and
        # insert the dependency actions in between
        tree.push leaf if leaf.actions.length
        leaf = module: module, actions: []
        build_tree action
      else
        leaf.actions.push action
    tree.push leaf
  for module in modules then build_tree module
  tree

# ###
# Load a module and return its actions
# A module may be prefixed with:
# *   "?": Load this module only if it is defined by the user in the run list.
# *   "!": Force this module to be loaded and executed, apply to "fast" mode.
# ###
# Tree::load_module = (module) ->
#   @cache ?= {}
#   return @cache[module] if @cache[module]
#   @cache[module] = actions = []
#   # Load the module
#   # required = false
#   # [_, meta, module] = /([\!\?]?)(.*)/.exec module
#   # console.log meta, module
#   # switch meta
#   #   when '?' then # nothing yet
#   #   when '!' then required = true
#   actions = load module
#   actions = [actions] unless Array.isArray actions
#   for action, i in actions
#     # Module dependencies
#     if typeof action is 'string'
#       actions.push action
#       continue
#     action = callback: action if typeof action is 'function'
#     action.hidden ?= true unless action.name
#     action.name ?= "#{module}/#{i}"
#     action.module ?= module
#     action.index ?= i
#     # action.required ?= required
#     action.skip = false
#     action.required = true if module.indexOf('phyla/bootstrap') is 0
#     actions.push action
#   actions

###
Load a module and return its actions.

Module actions when defining a string dependency may be prefixed with:  

*   "?": Load this module only if it is defined by the user in the run list.
*   "!": Force this module to be loaded and executed, apply to "fast" mode.

###
Tree::load_module = (module) ->
  @cache ?= {}
  return @cache[module] if @cache[module]
  # Load the module
  required = false
  [_, meta, module] = /([\!\?]?)(.*)/.exec module
  switch meta
    when '?' then # nothing yet
    when '!' then required = true
  # Load the module
  actions = load module
  actions = [actions] unless Array.isArray actions
  for callback, i in actions
    # Module dependencies
    continue if typeof callback is 'string'
    callback = actions[i] = callback: callback if typeof callback is 'function'
    callback.hidden ?= true unless callback.name
    callback.name ?= "#{module}/#{i}"
    callback.module ?= module
    callback.index ?= i
    callback.skip ?= false
    callback.required = true if required
  @cache[module] = actions

module.exports = (modules, options, callback)->
  (new Tree).actions modules, options, callback
module.exports.Tree = Tree
