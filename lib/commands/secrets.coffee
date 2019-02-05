
fs = require 'fs'
crypto = require 'crypto'
yaml = require 'js-yaml'
generator = require 'generate-password'
get = require 'lodash.get'
set = require 'lodash.set'
unset = require 'lodash.unset'

class Store
  constructor: (options) ->
    @store = options.store
    @password = options.password or process.env[options.envpw]
    @algorithm = 'aes-256-ctr'
  unset: (key, callback) ->
    @get (err, secrets) =>
      unset secrets, key
      @set secrets, callback
  get: ->
    # (callback)
    if arguments.length is 1
      callback = arguments[0]
    # (key, callback)
    else if arguments.length is 2
      key = arguments[0]
      callback = arguments[1]
    @_read (err) =>
      @decrypt @raw, (err, secrets) ->
        return callback err if err
        if key
          callback null, get secrets, key
        else
          callback null, secrets
  set: (secrets, callback) ->
    # (secrets, callback)
    if arguments.length is 2
      secrets = arguments[0]
      callback = arguments[1]
    # (key, value, callback)
    else if arguments.length is 3
      key = arguments[0]
      value = arguments[1]
      callback = arguments[2]
      @get (err, secrets) =>
        return callback err if err
        set secrets, key, value
        @set secrets, callback
      return
    @_read (err) =>
      @encrypt secrets, (err, secrets) =>
        return callback err if err
        @raw = Buffer.from(secrets)
        data = Buffer.concat [@iv, @raw]
        fs.writeFile @store, data, (err, data) ->
          callback err
  init: (callback) ->
    @exists (err, exists) =>
      return callback err if err
      return callback Error 'Store already created' if exists
      iv = crypto.randomBytes 16
      fs.writeFile @store, iv, (err) ->
        callback err
  _read: (callback) ->
    return callback null, @iv, @raw if @iv and @raw
    fs.stat @store, (err) =>
      return callback Error 'Secret store not initialized' if err
      fs.readFile @store, (err, data) =>
        return callback err if err
        @iv = data.slice 0, 16
        @raw = data.slice 16
        callback null, @iv, @raw
  # Check if the store is created
  exists: (callback) ->
    fs.stat @store, (err) ->
      callback null, !err
  # Encrypt some text
  encrypt: (secrets, callback) ->
    text = JSON.stringify secrets
    @_read (err) =>
      return callback err if err
      key = crypto.createHash('sha256').update(@password).digest().slice(0, 32)
      cipher = crypto.createCipheriv @algorithm, key, @iv
      crypted = cipher.update text, 'utf8', 'hex'
      crypted += cipher.final 'hex'
      callback null, crypted
  # Decrypt some text
  decrypt: (text, callback) ->
    @_read (err) =>
      return callback err if err
      text = text.toString 'utf8' if Buffer.isBuffer text
      key = crypto.createHash('sha256').update(@password).digest().slice(0, 32)
      decipher = crypto.createDecipheriv @algorithm, key, @iv
      dec = decipher.update text, 'hex', 'utf8'
      dec += decipher.final 'utf8'
      secrets = JSON.parse dec or '{}'
      callback null, secrets

module.exports = (params, config, callback) ->
  module.exports[params.action] params, config, callback

module.exports.Store = Store

module.exports['init'] = (params, config, callback) ->
  store = new Store params
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
  store = new Store params
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
  store = new Store params
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
  store = new Store params
  store.get (err, data) ->
    if err
      process.stderr.write "#{err.message}" + '\n'
    else
      data = yaml.safeDump data
      process.stdout.write "#{data}" + '\n'
    callback err
  
module.exports['set'] = (params, config, callback) ->
  store = new Store params
  store.get (err, data) ->
    return callback err if err
    # Secret already set, need the overwrite option
    [property, password] = params.property.split ' '
    password_generated = false
    value = get data, property
    if value and not params.overwrite
      process.stderr.write "Fail to save existing secret, use the \"overwrite\" option." + '\n'
      return callback()
    unless password
      password_generated = true
      password = generator.generate
        length: 10,
        numbers: true
    store.set property, password, (err) ->
      if err
        process.stderr.write "#{err.message}" + '\n'
      else
        process.stderr.write "Secret store updated." + '\n'
        process.stdout.write password + '\n' if password_generated
      callback err
