
normalize = require '../../lib/config/normalize'
store = require '../../lib/config/store'
nikita = require 'nikita'
fs = require 'fs'

describe 'normalize deps required', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true

  it 'validate cluster reference when false', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify
      deps: 'dep_a': cluster: 'anywhere', service: 'anything', module: "#{tmp}/dep_a", required: false
    store normalize
      clusters: 'cluster_a': services: 'service_a': module: "#{tmp}/a"
    .service 'cluster_a', 'service_a'
    .deps
    .should.eql
      'dep_a': cluster: 'anywhere', service: 'anything', module: "#{tmp}/dep_a", required: false, disabled: true
    
  it 'validate cluster reference, when true', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify
      deps: 'dep_a': cluster: 'cluster_b', service: 'anything', module: "#{tmp}/dep_a", required: true
    ( ->
      store normalize
        clusters: 'cluster_a': services: 'service_a': module: "#{tmp}/a"
      .service 'cluster_a', 'service_a'
    ).should.throw 'Invalid Cluster Reference: cluster "cluster_b" is not defined'
  
  it 'validate service reference, when false', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify
      deps: 'dep_a': service: 'anything', module: "#{tmp}/dep_a", required: false
    store normalize
      clusters: 'cluster_a': services: 'service_a': module: "#{tmp}/a"
    .service 'cluster_a', 'service_a'
    .deps
    .should.eql
      'dep_a': cluster: 'cluster_a', service: 'anything', module: "#{tmp}/dep_a", required: false, disabled: true
  
  it 'validate service reference based on service id, when true', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    ( ->
      store normalize
        clusters: 'cluster_a': services: 'service_a':
          module: "#{tmp}/a"
          deps: 'dep_a': service: 'dep_a', module: "#{tmp}/dep_a", required: true
      .service 'cluster_a', 'service_a'
    ).should.throw "Required Dependency: unsatisfied dependency \"dep_a\" in service \"cluster_a:service_a\", service \"dep_a\" in cluster \"cluster_a\" is not defined"

  it 'validate service reference based on module, when true', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    ( ->
      store normalize
        clusters: 'cluster_a': services: 'service_a':
          module: "#{tmp}/a"
          deps: 'dep_a': module: "#{tmp}/dep_a", required: true
      .service 'cluster_a', 'service_a'
    ).should.throw "Required Dependency: unsatisfied dependency \"dep_a\" in service \"cluster_a:service_a\", module \"#{tmp}/dep_a\" in cluster \"cluster_a\" is not defined"

  it 'validate local', ->
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    # Valid
    store normalize
      clusters: 'cluster_a': services:
        'dep_a':
          module: "#{tmp}/dep_a"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
        'service_a':
          module: "#{tmp}/a"
          affinity: type: 'nodes', match: 'any', values: 'b.fqdn'
          deps: 'dep_a': module: "#{tmp}/dep_a", local: true, required: true
      nodes:
        'a.fqdn': {}
        'b.fqdn': {}
        'c.fqdn': {}
    .service 'cluster_a', 'service_a'
    # Invalid
    ( ->
      store normalize
        clusters: 'cluster_a': services:
          'dep_a':
            module: "#{tmp}/dep_a"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
          'service_a':
            module: "#{tmp}/a"
            affinity: type: 'nodes', match: 'any', values: 'b.fqdn'
            deps: 'dep_a': module: "#{tmp}/dep_a", local: true, required: true
        nodes:
          'a.fqdn': {}
          'b.fqdn': {}
          'c.fqdn': {}
      .service 'cluster_a', 'service_a'
    ).should.throw 'Required Local Dependency: service "service_a" in cluster "cluster_a" require service "dep_a" in cluster "cluster_a" to be present on node b.fqdn'
