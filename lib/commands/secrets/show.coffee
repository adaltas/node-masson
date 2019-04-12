
secrets = require '../../secrets'
yaml = require 'js-yaml'

module.exports = ({params}, config, callback) ->
  # if the size of a password is > MAX_LENGTH chars,
  # replace the password inplace in the given object
  MAX_LENGTH = 40 # max password length to be displayed
  reduceSize = (obj) ->
    for k,v of obj
      obj[k] = v.substring(0, MAX_LENGTH) + '...' if typeof v is 'string' and v.length > MAX_LENGTH
      reduceSize v if typeof v is 'object'

  store = secrets params
  store.get (err, data) ->
    if err
      process.stderr.write "#{err.message}" + '\n'
    else
      reduceSize(data) if process.stdin.isTTY and not params.full?
      data = yaml.safeDump data
      process.stdout.write "#{data}" + '\n'
    callback err
  
