
fs = require 'fs'
crypto = require 'crypto'
yaml = require 'js-yaml'
generator = require 'generate-password'

class Store
  constructor: (options) ->
    @store = options.store
    @password = options.password or process.env[options.envpw]
    @algorithm = 'aes-256-ctr'
  get: (callback) ->
    @_read (err) =>
      @decrypt @raw, (err, secrets) ->
        return callback err if err
        secrets = JSON.parse secrets or '{}'
        callback null, secrets
  set: (secrets, callback) ->
    @_read (err) =>
      secrets = JSON.stringify secrets
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
  encrypt: (text, callback) ->
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
      callback null, dec

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

module.exports['get'] = (params, config, callback) ->
  store = new Store params
  store.get (err, data) ->
    if err
      process.stderr.write "#{err.message}" + '\n'
    else unless data[params.property]
      process.stderr.write "Property does not exists" + '\n'
    else
      process.stdout.write "#{data[params.property]}" + '\n'
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
    if data[params.property] and not params.overwrite
      process.stderr.write "Fail to save existing secret, use the \"overwrite\" option." + '\n'
      return callback()
    pw = generator.generate
      length: 10,
      numbers: true
    data[params.property] = pw
    store.set data, (err) ->
      if err
        process.stderr.write "#{err.message}" + '\n'
      else
        process.stderr.write "Secret store updated." + '\n'
        process.stdout.write pw + '\n'
      callback err
