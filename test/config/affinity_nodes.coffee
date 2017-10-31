
normalize = require '../../lib/config/normalize'
affinity = require '../../lib/config/affinities'
store = require '../../lib/config/store'
fs = require 'fs'
nikita = require 'nikita'

describe 'affinity nodes', ->

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
      affinity.handlers.nodes.normalize
        type: 'nodes', values: 'fqdn_a'
      .should.eql
        type: 'nodes', values: 'fqdn_a': true
            
    it 'values as array', ->
      affinity.handlers.nodes.normalize
        type: 'nodes', values: ['fqdn_a']
      .should.eql
        type: 'nodes', values: 'fqdn_a': true
            
    it 'values as object', ->
      affinity.handlers.nodes.normalize
        type: 'nodes', values: 'fqdn_a': true
      .should.eql
        type: 'nodes', values: 'fqdn_a': true
    
    it 'Required Option: match', ->
      ( ->
        affinity.handlers.nodes.normalize
          type: 'nodes', values: 'fqdn_a': true, 'fqdn_b': true
      ).should.throw 'Required Property: "match", when more than one values'

  describe 'resolve', ->
    
    it 'match single', ->
      fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
      s = store normalize
        clusters: 'cluster_a': services: 'service_a':
          module: "#{tmp}/a"
          affinity: type: 'nodes', values: 'a.fqdn': true
        nodes:
          'a.fqdn': {}
          'b.fqdn': {}
      affinity.handlers.nodes.resolve s.config(),
        s.service('cluster_a', 'service_a').affinity[0]
      .should.eql ['a.fqdn']
        
    it 'match any', ->
      fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
      s = store normalize
        clusters: 'cluster_a': services: 'service_a':
          module: "#{tmp}/a"
          affinity: type: 'nodes', match: 'any', values: 'a.fqdn': true, 'b.fqdn': true
        nodes:
          'a.fqdn': {}
          'b.fqdn': {}
      affinity.handlers.nodes.resolve s.config(),
        s.service('cluster_a', 'service_a').affinity[0]
      .should.eql ['a.fqdn', 'b.fqdn']
        
    it 'match none', ->
      fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
      s = store normalize
        clusters: 'cluster_a': services: 'service_a':
          module: "#{tmp}/a"
          affinity: type: 'nodes', match: 'none', values: 'a.fqdn': true, 'c.fqdn': true
        nodes:
          'a.fqdn': {}
          'b.fqdn': {}
      affinity.handlers.nodes.resolve s.config(),
        s.service('cluster_a', 'service_a').affinity[0]
      .should.eql ['b.fqdn']
      
    
