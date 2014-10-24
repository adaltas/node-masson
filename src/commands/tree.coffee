
util = require 'util'
tree = require '../tree'
config = require '../config'
params = require '../params'

###
List all the actions to execute

`ryba -c ./config tree -h hadoop1.hadoop -r install`

###
module.exports = ->
  params = params.parse()
  hosts = Object.keys config.servers
  server = config.servers[params.host]
  return util.print "\x1b[31mInvalid server \"#{params.host}\"\x1b[39m\n" unless server
  # modules = server.run[params.run]
  modules = server.modules
  params.command = params.run
  return util.print "\x1b[31mInvalid run list \"#{server.run}\"\x1b[39m\n" unless modules
  tree(modules, params)
  .on 'module', (path) ->
    util.print "\x1b[32m#{path}\x1b[39m\n"
  .on 'action', (action) ->
    util.print "  #{action.name or action.id}\n" unless action.hidden
