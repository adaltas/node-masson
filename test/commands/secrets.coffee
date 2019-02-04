
nikita = require 'nikita'
{Store} = require '../../lib/commands/secrets'

describe 'command configure', ->
  
  tmp = '/tmp/masson_store'
  beforeEach ->
    nikita
    .system.remove tmp
    .promise()
      
  it 'init', (next) ->
    store = new Store
      store: tmp
      password: 'mysecret'
    store.init (err) ->
      return next err if err
      store.init (err) ->
        err.message.should.eql 'Store already created'
        next()
          
  it 'setget all', (next) ->
    store = new Store
      store: tmp
      password: 'mysecret'
    store.init (err) ->
      return next err if err
      store.set a_key: 'a value', (err) ->
        return next err if err
        store.get (err, secrets) ->
          return next err if err
          secrets.a_key.should.eql 'a value'
          next()
