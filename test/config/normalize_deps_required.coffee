
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'
import nikita from 'nikita'
import fs from 'fs'

describe 'normalize deps required', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true

  it 'validate cluster reference when false', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify
      deps: 'dep_a': cluster: 'anywhere', service: 'anything', module: "#{tmp}/dep_a", required: false
    store await normalize
      clusters: 'cluster_a': services: 'service_a': module: "#{tmp}/a.json"
    .service 'cluster_a', 'service_a'
    .deps
    .should.eql
      'dep_a': cluster: 'anywhere', service: 'anything', module: "#{tmp}/dep_a", required: false, disabled: true
    
  it 'validate cluster reference, when true', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify
      deps: 'dep_a': cluster: 'cluster_b', service: 'anything', module: "#{tmp}/dep_a", required: true
    ( ->
      store await normalize
        clusters: 'cluster_a': services: 'service_a': module: "#{tmp}/a.json"
      .service 'cluster_a', 'service_a'
    ).should.throw 'Invalid Cluster Reference: cluster "cluster_b" is not defined'
  
  it 'validate service reference, when false', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify
      deps: 'dep_a': service: 'anything', module: "#{tmp}/dep_a", required: false
    store await normalize
      clusters: 'cluster_a': services: 'service_a': module: "#{tmp}/a.json"
    .service 'cluster_a', 'service_a'
    .deps
    .should.eql
      'dep_a': cluster: 'cluster_a', service: 'anything', module: "#{tmp}/dep_a", required: false, disabled: true
  
  it 'validate service reference based on service id, when true', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    store await normalize
      clusters: 'cluster_a': services: 'service_a':
        module: "#{tmp}/a.json"
        deps: 'dep_a': service: 'dep_a', module: "#{tmp}/dep_a.json", required: true
    .service 'cluster_a', 'service_a'
    .should.be.rejectedWith "Required Dependency: unsatisfied dependency \"dep_a\" in service \"cluster_a:service_a\", service \"dep_a\" in cluster \"cluster_a\" is not defined"
    # await normalize
    #   clusters: 'cluster_a': services: 'service_a':
    #     module: "#{tmp}/a.json"
    #     deps: 'dep_a': service: 'dep_a', module: "#{tmp}/dep_a.json", required: true
    # .should.be.rejectedWith "Required Dependency: unsatisfied dependency \"dep_a\" in service \"cluster_a:service_a\", service \"dep_a\" in cluster \"cluster_a\" is not defined"
    # await Promise.reject(Error 'hum')
    # try
    #   await normalize
    #     clusters: 'cluster_a': services: 'service_a':
    #       module: "#{tmp}/a.json"
    #       deps: 'dep_a': service: 'dep_a', module: "#{tmp}/dep_a.json", required: true
    # catch err
    #   console.log('!!!!!err', typeof err, err)
    # ( ->
    #   store await normalize
    #     clusters: 'cluster_a': services: 'service_a':
    #       module: "#{tmp}/a.json"
    #       deps: 'dep_a': service: 'dep_a', module: "#{tmp}/dep_a.json", required: true
    #   .service 'cluster_a', 'service_a'
    # ).should.throw "Required Dependency: unsatisfied dependency \"dep_a\" in service \"cluster_a:service_a\", service \"dep_a\" in cluster \"cluster_a\" is not defined"

  it 'validate service reference based on module, when true', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    await normalize
      clusters: 'cluster_a': services: 'service_a':
        module: "#{tmp}/a.json"
        deps: 'dep_a': module: "#{tmp}/dep_a.json", required: true
    .should.be.rejectedWith "Required Dependency: unsatisfied dependency \"dep_a\" in service \"cluster_a:service_a\", module \"#{tmp}/dep_a.json\" in cluster \"cluster_a\" is not defined"

  it 'validate local', ->
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    # Valid
    store await normalize
      clusters: 'cluster_a': services:
        'dep_a':
          module: "#{tmp}/dep_a.json"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
        'service_a':
          module: "#{tmp}/a.json"
          affinity: type: 'nodes', match: 'any', values: 'b.fqdn'
          deps: 'dep_a': module: "#{tmp}/dep_a.json", local: true, required: true
      nodes:
        'a.fqdn': {}
        'b.fqdn': {}
        'c.fqdn': {}
    .service 'cluster_a', 'service_a'
    # Invalid
    ( ->
      store await normalize
        clusters: 'cluster_a': services:
          'dep_a':
            module: "#{tmp}/dep_a"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
          'service_a':
            module: "#{tmp}/a"
            affinity: type: 'nodes', match: 'any', values: 'b.fqdn'
            deps: 'dep_a': module: "#{tmp}/dep_a.json", local: true, required: true
        nodes:
          'a.fqdn': {}
          'b.fqdn': {}
          'c.fqdn': {}
      .service 'cluster_a', 'service_a'
    ).should.throw 'Required Local Dependency: service "service_a" in cluster "cluster_a" require service "dep_a" in cluster "cluster_a" to be present on node b.fqdn'
