
util = require 'util'
parameters = require 'parameters'
params = require '../params'

module.exports = (config, params) ->
  process.stdout.write @help params.subcommand
  
