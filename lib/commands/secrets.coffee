
secrets = require '../secrets'
get = require 'lodash.get'
yaml = require 'js-yaml'

module.exports = (params, config, callback) ->
  module.exports[params.action] params, config, callback

module.exports['init'] = (params, config, callback) ->
  store = secrets params
  store.exists (err, exists) ->
    if exists
      process.stderr.write "Secret store is already initialised at \"#{params.store}\"." + '\n'
    else
      store.init (err) ->
        if err
          process.stderr.write "#{err.message}" + '\n'
        else
          process.stderr.write "Secret store is ready at \"#{params.store}\"." + '\n'
        callback()

module.exports['unset'] = (params, config, callback) ->
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

module.exports['get'] = (params, config, callback) ->
  store = secrets params
  store.get (err, secrets) ->
    secrets = get secrets, params.property
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

module.exports['show'] = (params, config, callback) ->
  store = secrets params
  store.get (err, data) ->
    if err
      process.stderr.write "#{err.message}" + '\n'
    else
      data = yaml.safeDump data
      process.stdout.write "#{data}" + '\n'
    callback err
  
module.exports['set'] = (params, config, callback) ->
  store = secrets params
  store.get (err, data) ->
    return callback err if err
    # Secret already set, need the overwrite option
    [property, password] = params.property.split ' '
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
