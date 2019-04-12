
secrets = require '../../secrets'
get = require 'lodash.get'
yaml = require 'js-yaml'

module.exports = ({params}, config, callback) ->
  store = secrets params
  store.get params.property, (err, value) ->
    unless value
      process.stderr.write "Property \"#{params.property}\" does not exist." + '\n'
      return callback()
    store.unset params.property, (err, data) ->
      if err
        process.stderr.write "#{err.message}" + '\n'
      else
        process.stderr.write "Property \"#{params.property}\" removed." + '\n'
      callback err
