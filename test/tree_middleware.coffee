
should = require 'should'
nikita = require 'nikita'
tree = require '../lib/tree'

describe 'tree middleware', ->

  tmp = '/tmp/masson-test'
  beforeEach (next) ->
    require('module')._cache = {}
    nikita.mkdir destination: tmp, next
  afterEach (next) -> nikita.remove tmp, next

  it 'is a async function', (next) ->
    nikita.write
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
    nikita.write
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






