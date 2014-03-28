
should = require 'should'
load = require '../src/load'

describe 'load', ->

  it 'load local module', (next) ->
    mod = load './src/load'
    mod.should.be.a.Function
    next()

  it 'load global module', (next) ->
    mod = load 'mecano/lib/misc'
    mod.should.be.an.Object
    next()
