
normalize = require '../../lib/config/normalize'
store = require '../../lib/config/store'
nikita = require 'nikita'
fs = require 'fs'

describe 'normalize service affinity', ->

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
    
  it 'no affinity', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    store normalize
      clusters: 'cluster_a': services:
        'service_a': module: "#{tmp}/a"
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2'
    .chain()
    .service 'cluster_a', 'service_a', (service) ->
      service.nodes.should.eql []
    .node 'a.fqdn', (node) ->
      node.services.should.eql []
      
  it 'is enriched from cluster services', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    store normalize
      clusters: 'cluster_a': services:
        'service_a':
          module: "#{tmp}/a"
          affinity:
            type: 'nodes'
            values: 'b.fqdn'
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2'
    .chain()
    .service 'cluster_a', 'service_a', (service) ->
      service.nodes.should.eql ['b.fqdn']
    .node 'b.fqdn', (node) ->
     node.services.should.eql [
       cluster: 'cluster_a', service: 'service_a', module: "#{tmp}/a"
     ]
  
