
secrets = require '../../secrets'
get = require 'lodash.get'

module.exports = ({params}, config, callback) ->
  store = secrets params
  store.get (err, data) ->
    return callback err if err
    # Secret already set, need the overwrite option
    [property, password] = params.property
    password_generated = false
    value = get data, property
    if value and not params.overwrite
      process.stderr.write "Fail to save existing secret, use the \"overwrite\" option." + '\n'
      return callback()
    store_password = (password) ->
      store.set property, password, (err) ->
        if err
          process.stderr.write "#{err.message}" + '\n'
        else
          process.stderr.write "Secret store updated." + '\n'
          process.stdout.write password + '\n' if password_generated
        callback err
    # Provided as argument
    if password
      store_password password
    else
      # Provided generated
      if process.stdin.isTTY
        password_generated = true
        password = store.password()
        store_password password
      # Obtained from stdin
      else
        password = ''
        process.stdin.on 'data', (chunk) ->
          password += chunk
        process.stdin.on 'end', ->
          store_password password
