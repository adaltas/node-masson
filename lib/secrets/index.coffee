
fs = require 'fs'
crypto = require 'crypto'
yaml = require 'js-yaml'
generator = require 'generate-password'
get = require 'lodash.get'
set = require 'lodash.set'
unset = require 'lodash.unset'

class Store
  constructor: (@options={}) ->
    @options.store ?= '.secrets'
    @options.envpw ?= 'MASSON_SECRET_PW'
    @options.password ?= process.env[@options.envpw]
    @options.algorithm ?= 'aes-256-ctr'
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
      secrets = @decrypt @raw, @iv
      if key
        callback null, get secrets, key
      else
        callback null, secrets
  getSync: ->
    # (callback)
    if arguments.length is 1
      key = arguments[0]
    @_readSync()
    secrets = @decrypt @raw, @iv
    if key
      get secrets, key
    else
      secrets
  set: (sync, secrets, callback) ->
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
      secrets = @encrypt secrets, @iv
      @raw = Buffer.from(secrets)
      data = Buffer.concat [@iv, @raw]
      fs.writeFile @options.store, data, (err, data) ->
        callback err
  init: (callback) ->
    @exists (err, exists) =>
      return callback err if err
      return callback Error 'Store already created' if exists
      iv = crypto.randomBytes 16
      fs.writeFile @options.store, iv, (err) ->
        callback err
  password: (options={}) ->
    generator.generate Object.assign
      length: 10,
      numbers: true
    , options
  _readSync: (callback) ->
    return [@iv, @raw] if @iv and @raw
    try
      fs.statSync @options.store
    catch err
      throw Error 'Secret store not initialized'
    data = fs.readFileSync @options.store
    @iv = data.slice 0, 16
    @raw = data.slice 16
    [@iv, @raw]
  _read: (callback) ->
    return callback null, @iv, @raw if @iv and @raw
    fs.stat @options.store, (err) =>
      return callback Error 'Secret store not initialized' if err
      fs.readFile @options.store, (err, data) =>
        return callback err if err
        @iv = data.slice 0, 16
        @raw = data.slice 16
        callback null, @iv, @raw
  # Check if the store is created
  exists: (callback) ->
    fs.stat @options.store, (err) ->
      callback null, !err
  # Encrypt some text
  encrypt: (secrets, iv) ->
    text = JSON.stringify secrets
    key = crypto.createHash('sha256').update(@options.password).digest().slice(0, 32)
    cipher = crypto.createCipheriv @options.algorithm, key, iv
    crypted = cipher.update text, 'utf8', 'hex'
    crypted += cipher.final 'hex'
    crypted
  # Decrypt some text
  decrypt: (text, iv) ->
    text = text.toString 'utf8' if Buffer.isBuffer text
    key = crypto.createHash('sha256').update(@options.password).digest().slice(0, 32)
    decipher = crypto.createDecipheriv @options.algorithm, key, iv
    dec = decipher.update text, 'hex', 'utf8'
    dec += decipher.final 'utf8'
    secrets = JSON.parse dec or '{}'
    secrets

module.exports = (options) ->
  new Store options
