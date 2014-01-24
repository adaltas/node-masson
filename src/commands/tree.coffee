
util = require 'util'
tree = require '../tree'
config = require '../config'
params = require '../params'

###
List all the actions to execute

`famas -c ./config tree -h hadoop1.hadoop -r install`

###
module.exports = ->
  hosts = config.servers.map (server) -> server.host
  server = hosts.indexOf(params.host)
  return util.print "\x1b[31mInvalid server \"#{server.host}\"\x1b[39m\n" if server is -1
  server = config.servers[server]
  modules = server.run[params.run]
  return util.print "\x1b[31mInvalid run list \"#{server.run}\"\x1b[39m\n" unless modules
  tree(modules, params)
  .on 'module', (path) ->
    util.print "\x1b[32m#{path}\x1b[39m\n"
  .on 'action', (action) ->
    util.print "  #{action.name}\n" unless action.hidden
