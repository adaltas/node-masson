parameters = require 'parameters'
params = require '../params'

module.exports = ->
  util.print parameters.help ctx.params.subcommand

