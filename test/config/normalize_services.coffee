
normalize = require '../../lib/config/normalize'
store = require '../../lib/config/store'
nikita = require 'nikita'
fs = require 'fs'

describe 'normalize services', ->

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
  
  it 'value is true', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    store normalize
      clusters:
        'cluster_a':
          services:
            "#{tmp}/a": true
    .service 'cluster_a', "#{tmp}/a"
    .should.eql
      id: "#{tmp}/a"
      cluster: 'cluster_a'
      module: "#{tmp}/a"
      affinity: []
      deps: {}
      commands: {}
      nodes: []
      service_by_nodes: {}
        
  it 'module is string', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    store normalize
      clusters:
        'cluster_a':
          services:
            'service_a':
              module: "#{tmp}/a"
    .service 'cluster_a', 'service_a'
    .should.eql
      id: 'service_a'
      cluster: 'cluster_a'
      module: "#{tmp}/a"
      affinity: []
      deps: {}
      commands: {}
      nodes: []
      service_by_nodes: {}
  
