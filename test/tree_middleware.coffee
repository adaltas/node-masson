
should = require 'should'
mecano = require 'mecano'
tree = require '../lib/tree'

describe 'tree middleware', ->

  tmp = '/tmp/masson-test'
  beforeEach (next) ->
    require('module')._cache = {}
    mecano.mkdir destination: tmp, next
  afterEach (next) -> mecano.remove tmp, next

  it 'is a async function', (next) ->
    mecano.write
      destination: "#{tmp}/module_1.coffee"
      content: """
      exports = module.exports = []
      exports.push (next) ->
        setTimeout next, 100
      """
    , (err) ->
      tree("#{tmp}/module_1").middlewares command: 'install', (err, middlewares) ->
        middlewares.length.should.eql 1
        middlewares[0].should.have.properties
          name: null
          commands: []
          modules: []
          id: "#{tmp}/module_1/0"
          module: "#{tmp}/module_1"
          index: 0
        next()

  it 'is an object with a function callback', (next) ->
    mecano.write
      destination: "#{tmp}/module_1.coffee"
      content: """
      exports = module.exports = []
      exports.push name: 'middleware 1', handler: (next) ->
        setTimeout next, 100
      """
    , (err) ->
      tree("#{tmp}/module_1").middlewares command: 'install', (err, middlewares) ->
        middlewares.length.should.eql 1
        middlewares[0].should.have.properties
          name: 'middleware 1'
          commands: []
          modules: []
          id: "#{tmp}/module_1/0"
          module: "#{tmp}/module_1"
          index: 0
        next()






