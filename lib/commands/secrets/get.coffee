
secrets = require '../../secrets'
get = require 'lodash.get'
yaml = require 'js-yaml'

module.exports = ({params}, config, callback) ->
  store = secrets params
  store.get (err, secrets) ->
    for property in params.properties
      secrets = get secrets, property
      if err
        process.stderr.write "#{err.message}" + '\n'
      else unless secrets
        process.stderr.write "Property does not exists" + '\n'
      else
        if typeof secrets is 'string'
          process.stdout.write "#{secrets}" + '\n'
        else
          data = yaml.safeDump secrets
          process.stdout.write "#{data}" + '\n'
      callback err
