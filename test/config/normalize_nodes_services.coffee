
normalize = require '../../lib/config/normalize'
store = require '../../lib/config/store'
nikita = require 'nikita'
fs = require 'fs'

describe 'normalize nodes services', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
          
  it 'must reference existing service', ->
    ( ->
      store normalize
        clusters: 'cluster_a': services: {}
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2', services: [
            cluster: 'cluster_a', service: 'service_a', options: a_key: 'a value'
          ]
    ).should.throw 'Node Invalid Service: node "b.fqdn" references missing service "service_a" in cluster "cluster_a"'

  it 'can be declared as an object', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    store normalize
      clusters: 'cluster_a': services:
        'service_a':
          module: "#{tmp}/a"
          affinity: type: 'nodes', values: 'b.fqdn'
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2', services:
          'cluster_a:service_a': 'a_key': 'a value'
    .chain()
    .node 'b.fqdn', (node) ->
      node.services.length is 1
      node.services[0].should.eql
        cluster: 'cluster_a'
        service: 'service_a'
        module: "#{tmp}/a"
        options: 'a_key': 'a value'

  it 'merge options', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    store normalize
      clusters: 'cluster_a': services:
        'service_a':
          module: "#{tmp}/a"
          affinity: type: 'nodes', values: 'b.fqdn'
          options: overwritten_key: 'a value'
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2', services: [
          cluster: 'cluster_a', service: 'service_a', options: overwritten_key: 'an overwritten value'
        ]
    .service 'cluster_a', 'service_a'
    .instances
    .filter((instance) -> instance.node.id is 'b.fqdn')[0]
    .options.overwritten_key.should.eql 'an overwritten value'

  it 'contain cluster, service and module', ->
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/dep_b.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    store normalize
      clusters: 'cluster_a': services:
        'dep_a':
          module: "#{tmp}/dep_a"
          affinity: type: 'nodes', values: 'a.fqdn'
        'service_a':
          module: "#{tmp}/a"
          deps:
            'my_dep_a': module: "#{tmp}/dep_a"
          affinity: type: 'nodes', values: 'a.fqdn'
      nodes:
        'a.fqdn': services: [
          cluster: 'cluster_a', service: 'service_a'
        ]
    .node 'a.fqdn'
    .services.should.eql [
      cluster: 'cluster_a', service: 'dep_a', module: "#{tmp}/dep_a"
    ,
      cluster: 'cluster_a', service: 'service_a', module: "#{tmp}/a"
    ]

  it 're-order services based on graph', ->
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/dep_b.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    store normalize
      clusters: 'cluster_a': services:
        'dep_a':
          module: "#{tmp}/dep_a"
          affinity: type: 'nodes', values: 'b.fqdn'
        'dep_b':
          module: "#{tmp}/dep_b"
          deps: 'my_dep_a': module: "#{tmp}/dep_a"
        'service_a':
          module: "#{tmp}/a"
          deps:
            'my_dep_a': module: "#{tmp}/dep_a"
            'my_dep_b': module: "#{tmp}/dep_b", local: true, auto: true
          affinity: type: 'nodes', values: 'b.fqdn'
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2', services: [
          cluster: 'cluster_a', service: 'service_a'
        ]
    .node 'b.fqdn'
    .services.should.eql [
      cluster: 'cluster_a', service: 'dep_a', module: "#{tmp}/dep_a"
    ,
      cluster: 'cluster_a', service: 'dep_b', module: "#{tmp}/dep_b"
    ,
      cluster: 'cluster_a', service: 'service_a', module: "#{tmp}/a"
    ]
