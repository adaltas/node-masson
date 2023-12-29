
import nikita from 'nikita'
import secrets from 'masson/secrets'

describe 'command configure', ->

  tmp = '/tmp/masson-test/'
  beforeEach ->
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
      
  it 'init', ->
    store = secrets
      store: "#{tmp}/a_store"
      password: 'mysecret'
    await store.init()
    store.init()
    .should.be.rejectedWith 'Store already created'
          
  it 'setget all', ->
    store = secrets
      store: "#{tmp}/a_store"
      password: 'mysecret'
    await store.init()
    await store.set a_key: 'a value'
    values = await store.get()
    values.a_key.should.eql 'a value'
            
  it 'get key', ->
    store = secrets
      store: "#{tmp}/a_store"
      password: 'mysecret'
    await store.init()
    await store.set
      a_key: 'a value'
      b: key: 'b value'
    value = await store.get 'a_key'
    value.should.eql 'a value'
    value = await store.get 'b.key'
    value.should.eql 'b value'
              
  it 'get keys', ->
    store = secrets
      store: "#{tmp}/a_store"
      password: 'mysecret'
    await store.init()
    await store.set
      some: keys: 
        a: 'a value'
        b: 'b value'
    values = await store.get 'some.keys'
    values.should.eql
      a: 'a value'
      b: 'b value'
            
  it 'set key', ->
    store = secrets
      store: "#{tmp}/a_store"
      password: 'mysecret'
    await store.init()
    await store.set
      a_key: 'a value'
    await store.set 'b.key', 'b value'
    values = await store.get()
    values.should.eql 
      a_key: 'a value'
      b: key: 'b value'
              
  it 'set keys', ->
    store = secrets
      store: "#{tmp}/a_store"
      password: 'mysecret'
    await store.init()
    await store.set
      a_key: 'a value'
    await store.set 'keys', 
      a: 'a value'
      b: 'b value'
    values = await store.get()
    values.should.eql 
      a_key: 'a value'
      keys:
        a: 'a value'
        b: 'b value'
              
  it 'unset key', ->
    store = secrets
      store: "#{tmp}/a_store"
      password: 'mysecret'
    await store.init()
    await store.set
      some: keys: 
        a: 'a value'
        b: 'b value'
    await store.unset 'some.keys.a'
    values = await store.get()
    values.should.eql 
      some: keys:
        b: 'b value'
