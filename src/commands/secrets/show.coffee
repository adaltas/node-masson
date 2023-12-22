
secrets = require 'masson/secrets/index'
yaml = require 'js-yaml'
import util from 'node:util'

export default ({params}, config) ->
  # if the size of a password is > MAX_LENGTH chars,
  # replace the password inplace in the given object
  MAX_LENGTH = 40 # max password length to be displayed
  reduceSize = (obj) ->
    for k, v of obj
      obj[k] = v.substring(0, MAX_LENGTH) + '...' if typeof v is 'string' and v.length > MAX_LENGTH
      reduceSize v if typeof v is 'object'
  store = secrets params
  return process.stderr.write [
    'Store does not exists, '
    'run the `init` command to initialize it.\n'
  ].join '' unless await store.exists()
  try
    data = await store.get()
    reduceSize(data) if process.stdin.isTTY and not params.full?
    output = switch params.format
      when 'json' then JSON.stringify data
      when 'prettyjson' then util.inspect data,
        colors: process.stdout.isTTY
        depth: Infinity
      when 'yaml' then yaml.dump data
    process.stdout.write "#{output}" + '\n'
  catch err
    process.stderr.write "#{err.message}" + '\n'
  
