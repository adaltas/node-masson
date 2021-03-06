
normalize = require '../../lib/config/normalize'
affinity = require '../../lib/config/affinities'
store = require '../../lib/config/store'
fs = require 'fs'
nikita = require 'nikita'

describe 'affinity services', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
    nikita
    .system.mkdir target: tmp
    .promise()
  afterEach ->
    nikita
    .system.remove tmp
    .promise()
    
  describe 'normalize', ->
  
    it 'values as string', ->
      affinity.handlers.services.normalize
        type: 'services', values: 'service/a'
      .should.eql
        type: 'services', values: 'service/a': true
            
    it 'values as array', ->
      affinity.handlers.services.normalize
        type: 'services',  values: ['service/a']
      .should.eql
        type: 'services', values: 'service/a': true
            
    it 'values as object', ->
      affinity.handlers.services.normalize
        type: 'services', values: {'service/a': true}
      .should.eql
        type: 'services', values: 'service/a': true
