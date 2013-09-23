
should = require 'should'
load = require '../src/load'

describe 'load', ->

  mecano = require 'mecano/lib/misc'


  it 'load local module', (next) ->
    mod = load('./src/load')
    mod.should.be.a 'function'
    next()

  it 'load global module', (next) ->
    mod = load('mecano/lib/misc')
    mod.should.be.a 'object'
    next()
