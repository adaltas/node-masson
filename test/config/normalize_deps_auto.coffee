
normalize = require '../../lib/config/normalize'
store = require '../../lib/config/store'
nikita = require 'nikita'
fs = require 'fs'

describe 'normalize deps auto', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
  
  it 'deps is automatically registered if not defined', ->
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    services = []
    store normalize
      clusters: 'cluster_a': services:
        'service_a':
          module: "#{tmp}/a"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
          deps: 'my_dep_a': module: "#{tmp}/dep_a", local: true, auto: true
          configure: (service) ->
            services.push service
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2'
        'c.fqdn': ip: '10.10.10.3'
    .chain()
    .cluster 'cluster_a', (cluster) ->
      Object.keys(cluster.services).should.eql [ 'service_a', '/tmp/masson-test/dep_a' ]
    .service 'cluster_a', "service_a", (service) ->
      service.deps.my_dep_a.should.eql
        module: '/tmp/masson-test/dep_a'
        local: true
        auto: true
        cluster: 'cluster_a'
        service: '/tmp/masson-test/dep_a'
        disabled: false
    .service 'cluster_a', "#{tmp}/dep_a", (service) ->
      # Dependency should now be registered
      service.id.should.eql "#{tmp}/dep_a"
      service.module.should.eql "#{tmp}/dep_a"
      service.commands.should.eql {}
      # Affinity must be defined
      service.affinity.should.eql [
        type: 'nodes'
        match: 'any'
        values: 'a.fqdn': true, 'c.fqdn': true
      ]
      # Affinity must be resolved
      service.instances.map((instance) -> instance.node.id).should.eql ['a.fqdn', 'c.fqdn']
  
  it 'load the module', ->
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify
      commands:
        'install': 'some/module/install'
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    services = []
    s = store normalize
      clusters: 'cluster_a': services:
        'service_a':
          module: "#{tmp}/a"
          affinity: type: 'nodes', match: 'any', values: 'a.fqdn'
          deps: 'my_dep_a': module: "#{tmp}/dep_a", local: true, auto: true
          configure: (service) ->
            services.push service
      nodes:
        'a.fqdn': ip: '10.10.10.1'
    .chain()
    .service 'cluster_a', "#{tmp}/dep_a", (service) ->
      service.commands.install.should.eql ['some/module/install' ]
  
  it 'load the module recusively', ->
    fs.writeFileSync "#{tmp}/dep_b.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify
      deps:
        'my_dep_b': module: "#{tmp}/dep_b", local: true, auto: true
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    services = []
    s = store normalize
      clusters: 'cluster_a': services:
        'service_a':
          module: "#{tmp}/a"
          affinity: type: 'nodes', match: 'any', values: 'a.fqdn'
          deps: 'my_dep_a': module: "#{tmp}/dep_a", local: true, auto: true
          configure: (service) ->
            services.push service
      nodes:
        'a.fqdn': ip: '10.10.10.1'
    .chain()
    .service 'cluster_a', "#{tmp}/dep_b", (service) ->
      service.id.should.eql "#{tmp}/dep_b"
      service.module.should.eql "#{tmp}/dep_b"
      service.cluster.should.eql 'cluster_a'
      service.affinity.should.eql [ type: 'nodes', match: 'any', values: "a.fqdn": true ]
  
  it 'deps is defined but dont match', ->
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    services = []
    normalize
      clusters: 'cluster_a': services:
        'dep_a':
          module: "#{tmp}/dep_a"
          affinity: type: 'nodes', values: 'b.fqdn'
          options: 'key': 'value'
        'service_a':
          module: "#{tmp}/a"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
          deps: 'my_dep_a': module: "#{tmp}/dep_a", local: true, auto: true
          configure: (service) ->
            services.push service
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2'
        'c.fqdn': ip: '10.10.10.3'
    services.map (service) ->
      service.deps.my_dep_a.node.id
    .should.eql ['a.fqdn', 'c.fqdn']
