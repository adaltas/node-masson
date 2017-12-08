
util = require 'util'
parameters = require 'parameters'
params = require '../params'

module.exports = (params, config, callback = ->) ->
  # console.log params
  process.stdout.write @help params
  callback()
  
