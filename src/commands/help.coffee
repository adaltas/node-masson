
util = require 'util'
parameters = require 'parameters'
params = require '../params'

module.exports = ->
  util.print params.help params.parse().subcommand

