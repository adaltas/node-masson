
normalize = require '../../lib/config/normalize'
store = require '../../lib/config/store'
nikita = require 'nikita'
fs = require 'fs'

describe 'normalize clusters', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
    
  it 'validate root elements', ->
    try
      normalize clusters: true
      throw Error 'dont come here'
    catch err
      err.message.should.eql 'Invalid Clusters: expect an object, got true'
  
  it 'value is true', ->
    store normalize clusters: 'cluster_a': true
    .cluster 'cluster_a'
    .should.eql
      id: 'cluster_a'
      services: {}
  
