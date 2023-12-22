
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'
import nikita from 'nikita'
import fs from 'fs'

describe 'normalize deps', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
  
  it 'ensure module is defined', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify
      deps: 'dep_a_1': {}
    ( ->
      normalize
        clusters: 'cluster_a': services: 'service_a': module: "#{tmp}/a"
    ).should.throw 'Unidentified Dependency: require module or service property'
  
  it 'discover and resolve service id based on module', ->
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify
      deps: 'dep_a': module: "#{tmp}/dep_a"
    store normalize
      clusters: 'cluster_a': services:
        'dep_a_id': module: "#{tmp}/dep_a"
        'service_a': module: "#{tmp}/a"
    .service 'cluster_a', 'service_a'
    .deps['dep_a']
    .should.eql
      cluster: 'cluster_a', service: 'dep_a_id', module: "#{tmp}/dep_a", disabled: false

  it 'resolve base on service id converted to module', ->
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify
      deps: 'dep_a': "#{tmp}/dep_a"
    store normalize
      clusters: 'cluster_a': services:
        "#{tmp}/dep_a": true
        'service_a': module: "#{tmp}/a"
    .service 'cluster_a', "#{tmp}/dep_a"
    .should.eql
      id: "#{tmp}/dep_a"
      cluster: 'cluster_a'
      module: "#{tmp}/dep_a"
      affinity: []
      deps: {}
      commands: {}
      instances: []
      nodes: {}
  
  it 'load and merge module', ->
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify
      my_property: true
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify
      deps: 'dep_a': "#{tmp}/dep_a"
    store normalize
      clusters: 'cluster_a': services:
        "#{tmp}/dep_a": true
        'service_a': module: "#{tmp}/a"
    .service 'cluster_a', "#{tmp}/dep_a"
    .my_property
    .should.be.true()
  
  it 'validate service reference with multiple module match', ->
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    ( ->
      store normalize
        clusters: 'cluster_a': services:
          'dep_a_1': module: "#{tmp}/dep_a"
          'dep_a_2': module: "#{tmp}/dep_a"
          'service_a':
            module: "#{tmp}/a"
            deps: 'dep_a': module: "#{tmp}/dep_a"
      .service 'cluster_a', 'service_a'
      throw Error 'Dont get here'
    ).should.throw 'Invalid Service Reference: multiple matches for module "/tmp/masson-test/dep_a" in cluster "cluster_a"'
