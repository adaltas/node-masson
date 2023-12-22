
import fs from 'fs/promises'
import fsOrg from 'fs'
import crypto from 'crypto'
import yaml from 'js-yaml'
import generator from 'generate-password'
import get from 'lodash.get'
import set from 'lodash.set'
import unset from 'lodash.unset'

class Store
  constructor: (@options={}) ->
    @options.store ?= '.secrets'
    @options.envpw ?= 'MASSON_SECRET_PW'
    @options.password ?= process.env[@options.envpw]
    @options.algorithm ?= 'aes-256-ctr'
  unset: (key) ->
    secrets = await @get()
    unset secrets, key
    await @set secrets
  get: ->
    if arguments.length is 1
      key = arguments[0]
    else if arguments.length isnt 0
      throw Error "Invalid get arguments: got #{JSON.stringify arguments}"
    await @_read()
    secrets = @decrypt @raw, @iv
    if key
      get secrets, key
    else
      secrets
  getSync: ->
    # ()
    if arguments.length is 1
      key = arguments[0]
    else if arguments.length isnt 0
      throw Error "Invalid getSync arguments: got #{JSON.stringify arguments}"
    @_readSync()
    secrets = @decrypt @raw, @iv
    if key
      get secrets, key
    else
      secrets
  set: ->
    # (secrets)
    if arguments.length is 1
      secrets = arguments[0]
      await @_read()
      secrets = @encrypt secrets, @iv
      @raw = Buffer.from secrets
      data = Buffer.concat [@iv, @raw]
      await fs.writeFile @options.store, data
    # (key, value)
    else if arguments.length is 2
      key = arguments[0]
      value = arguments[1]
      secrets = await @get()
      set secrets, key, value
      await @set secrets
      return
    else throw Error "Invalid set arguments: got #{JSON.stringify arguments}"
  init: ->
    throw Error 'Store already created' if await @exists()
    iv = crypto.randomBytes 16
    await fs.writeFile @options.store, iv
  password: (options={}) ->
    generator.generate Object.assign
      length: 10,
      numbers: true
    , options
  _read: ->
    return if: @iv, raw: @raw if @iv and @raw
    try
      await fs.stat @options.store
      data = await fs.readFile @options.store
      @iv = data.slice 0, 16
      @raw = data.slice 16
      if: @iv, raw: @raw
    catch err
      throw err unless err.code is 'ENOENT'
      throw Error 'Secret store not initialized'
  _readSync: ->
    return [@iv, @raw] if @iv and @raw
    try
      fsOrg.statSync @options.store
    catch err
      throw Error 'Secret store not initialized'
    data = fsOrg.readFileSync @options.store
    @iv = data.slice 0, 16
    @raw = data.slice 16
    [@iv, @raw]
  # Check if the store is created
  exists: ->
    try
      await fs.stat @options.store
      true
    catch err
      throw err unless err.code is 'ENOENT'
      false
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
    try
      text = text.toString 'utf8' if Buffer.isBuffer text
      key = crypto.createHash('sha256').update(@options.password).digest().slice(0, 32)
      decipher = crypto.createDecipheriv @options.algorithm, key, iv
      dec = decipher.update text, 'hex', 'utf8'
      dec += decipher.final 'utf8'
      secrets = JSON.parse dec or '{}'
    catch err
      console.log "\x1b[31mError when decrypting password store. Is the password set and correct ?\x1b[0m"
      throw err

    secrets

export default (options) ->
  new Store options
