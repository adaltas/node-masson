
secrets = require '../../secrets'
get = require 'lodash.get'
yaml = require 'js-yaml'
util = require 'util'

module.exports = ({params}, config) ->
  store = secrets params
  return process.stderr.write [
    'Store does not exists, '
    'run the `init` command to initialize it.\n'
  ].join '' unless await store.exists()
  secrets = await store.get()
  for property in params.properties
    try
      secrets = get secrets, property
      unless secrets
        process.stderr.write "Property does not exists" + '\n'
      else
        if typeof secrets is 'string'
          process.stdout.write "#{secrets}" + '\n'
        else
          output = switch params.format
            when 'json' then JSON.stringify secrets
            when 'prettyjson' then util.inspect secrets,
              colors: process.stdout.isTTY
              depth: Infinity
            when 'yaml' then yaml.dump secrets
          process.stdout.write "#{output}" + '\n'
    catch err
      process.stderr.write "#{err.message}" + '\n'
