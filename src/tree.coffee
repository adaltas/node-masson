
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
-   `retry`   Re-execute an action multiple times, default to 2 or infinite if true
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
    try tree = @load_tree modules, options.command
    catch err
      ev.emit 'error', err
      callback err
      return
    # tree = @load_tree modules, options.command
    # Filter with the modules options
    if options.modules.length
      modules = tree.map (leaf) -> leaf.module
      modules = multimatch modules, options.modules
      # tree = @load_tree modules, options.command
      tree = @load_tree modules, options.command
      # Filter with the fast options
      tree = tree.filter( (leaf) =>
        return true if multimatch(leaf.module, options.modules).length
        leaf.actions = leaf.actions.filter (action) =>
          action.required
        leaf.actions.length
      ) if options.fast
    # Emit event and return actions
    actions = []
    for leaf in tree
      ev.emit 'module', leaf.module, leaf.actions
      for action in leaf.actions
        ev.emit 'action', action, leaf.module
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
Return a array of objects with the module name and its associated actions.

```json
[ { module: 'masson/bootstrap/cache_memory',
    actions: [ [Object], [Object] ] },
  { module: 'masson/bootstrap/mecano',
    actions: [ [Object], [Object] ] },
  { module: 'masson/bootstrap/', actions: [] },
  { module: 'masson/commons/java',
    actions: [ [Object], [Object], [Object], [Object], [Object], [Object] ] } ]
```
###
Tree::load_tree = (modules, command) ->
  called = {}
  tree = []
  normalize_action = (action) =>
    # Normalize
    action = modules: action if typeof action is 'string'
    action.commands ?= []
    action.commands = [action.commands] unless Array.isArray action.commands
    action.commands.push command if command and not action.commands.length
    action.modules ?= []
    action.modules = [action.modules] unless Array.isArray action.modules
    if typeof action.callback is 'string'
      action.modules.push action.callback 
      action.callback = null
    action
  build_module = (name, modules, filtering, parent) =>
    return if called[name]
    called[name] = true
    modules = @load_module name, parent unless modules
    leaf = module: name, actions: []
    for action in modules
      # Normalize
      action = normalize_action action
      # Filter
      continue if (filtering and action.commands.length is 0 and command isnt null and command isnt 'install') or (command and action.commands.length and command not in action.commands)
      # Discover
      if action.modules.length
        tree.push leaf if leaf.actions.length
        leaf = module: name, actions: []
        for childmod in action.modules
          f = if filtering is false then false else !action.commands.length
          build_module childmod, null, f, module
      leaf.actions.push action if action.callback
    # Push module into tree if actions or module is named and not already present
    if leaf.actions.length or (leaf.module and not (tree.some (l) -> l.module is leaf.module))
      tree.push leaf
  build_module null, modules, null
  # for module in modules then build_module module
  tree

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
    continue if typeof callback is 'string'
    throw Error "Module '#{module}' export an undefined action" unless callback?
    callback = actions[i] = callback: callback if typeof callback is 'function'
    # callback.hidden ?= true unless callback.name
    callback.id ?= "#{module}/#{i}"
    callback.name ?= null
    callback.module ?= module
    callback.index ?= i
    callback.skip ?= false
    callback.required = true if required
  @cache[module] = actions

module.exports = (modules, options, callback)->
  (new Tree).actions modules, options, callback
module.exports.Tree = Tree
