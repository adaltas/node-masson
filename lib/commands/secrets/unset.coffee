
secrets = require '../../secrets'
get = require 'lodash.get'
yaml = require 'js-yaml'

module.exports = ({params}, config) ->
  store = secrets params
  return process.stderr.write [
    'Store does not exists, '
    'run the `init` command to initialize it.\n'
  ].join '' unless await store.exists()
  for property in params.properties
    value = await store.get property
    unless value
      process.stderr.write "Property \"#{property}\" does not exist." + '\n'
      return
    try
      data = await store.unset property
      process.stderr.write "Property \"#{property}\" removed." + '\n'
    catch err
      process.stderr.write "#{err.message}" + '\n'
      throw err
