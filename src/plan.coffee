
crypto = require 'crypto'
load = require './load'
{flatten} = require './misc'

###
List all the actions to execute
###
module.exports = (mods, callback) ->
  actions = []
  loaded = {}
  mods = flatten mods
  # Require the module and look at its children
  l = (path) ->
    cmods = load path
    # A module may export a function
    if typeof cmods is 'function'
      cmods = [cmods] 
    else unless Array.isArray cmods
      callback new Error "Invalid wand module: \"#{path}\""
    for cmod in cmods
      if typeof cmod is 'string'
        return l cmod
      checksum = crypto.createHash('md5').update(cmod.toString()).digest('hex')
      unless loaded[checksum]
        actions.push cmod
        loaded[checksum] = true
  for mod in mods then l mod
  actions


