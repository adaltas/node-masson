
nikita = require 'nikita'
secrets = require '../../lib/secrets'

describe 'command configure', ->
  
  tmp = '/tmp/masson_store'
  beforeEach ->
    nikita
    .system.remove tmp
    .promise()
      
  it 'init', (next) ->
    store = secrets
      store: tmp
      password: 'mysecret'
    store.init (err) ->
      return next err if err
      store.init (err) ->
        err.message.should.eql 'Store already created'
        next()
          
  it 'setget all', (next) ->
    store = secrets
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
            
  it 'get key', (next) ->
    store = secrets
      store: tmp
      password: 'mysecret'
    store.init (err) ->
      return next err if err
      store.set
        a_key: 'a value'
        b: key: 'b value'
      , (err) ->
        return next err if err
        store.get 'a_key', (err, value) ->
          return next err if err
          value.should.eql 'a value'
          store.get 'b.key', (err, value) ->
            return next err if err
            value.should.eql 'b value'
            next()
              
  it 'get keys', (next) ->
    store = secrets
      store: tmp
      password: 'mysecret'
    store.init (err) ->
      return next err if err
      store.set
        some: keys: 
          a: 'a value'
          b: 'b value'
      , (err) ->
        return next err if err
        store.get 'some.keys', (err, secrets) ->
          return next err if err
          secrets.should.eql
            a: 'a value'
            b: 'b value'
          next()
            
  it 'set key', (next) ->
    store = secrets
      store: tmp
      password: 'mysecret'
    store.init (err) ->
      return next err if err
      store.set
        a_key: 'a value'
      , (err) ->
        return next err if err
        store.set 'b.key', 'b value', (err) ->
          return next err if err
          store.get (err, secrets) ->
            return next err if err
            secrets.should.eql 
              a_key: 'a value'
              b: key: 'b value'
            next()
              
  it 'set keys', (next) ->
    store = secrets
      store: tmp
      password: 'mysecret'
    store.init (err) ->
      return next err if err
      store.set
        a_key: 'a value'
      , (err) ->
        return next err if err
        store.set 'keys', 
          a: 'a value'
          b: 'b value'
        , (err) ->
          return next err if err
          store.get (err, secrets) ->
            return next err if err
            secrets.should.eql 
              a_key: 'a value'
              keys:
                a: 'a value'
                b: 'b value'
            next()
              
  it 'unset key', (next) ->
    store = secrets
      store: tmp
      password: 'mysecret'
    store.init (err) ->
      return next err if err
      store.set
        some: keys: 
          a: 'a value'
          b: 'b value'
      , (err) ->
        return next err if err
        store.unset 'some.keys.a', (err) ->
          return next err if err
          store.get (err, secrets) ->
            return next err if err
            secrets.should.eql 
              some: keys:
                b: 'b value'
            next()
