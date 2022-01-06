
normalize = require '../../lib/config/normalize'
store = require '../../lib/config/store'
nikita = require 'nikita'
fs = require 'fs'

describe 'normalize deps single', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
  
  it 'single match dep on another node', ->
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
          deps: 'my_dep_a': module: "#{tmp}/dep_a", single: true
          configure: (service) ->
            services.push service
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2'
        'c.fqdn': ip: '10.10.10.3'
    services.map (service) ->
      service.deps.my_dep_a.node.id
    .should.eql ['b.fqdn', 'b.fqdn']
      
  it 'single is compatible with local', ->
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
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn']
          deps: 'my_dep_a': module: "#{tmp}/dep_a", single: true, local: true
          configure: (service) ->
            services.push service
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2'
        'c.fqdn': ip: '10.10.10.3'
    services.map (service) ->
      if service.deps.my_dep_a
      then service.deps.my_dep_a.node.id
      else null
    .should.eql [null, 'b.fqdn']

  it 'dependency not loaded', ->
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    normalize
      clusters: 'cluster_a': services:
        'service_a':
          module: "#{tmp}/a"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn']
          deps: 'my_dep_a': module: "#{tmp}/dep_a", single: true
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2'
      
  it 'single throw if multiple', ->
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    ( ->
      normalize
        clusters: 'cluster_a': services:
          'dep_a':
            module: "#{tmp}/dep_a"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
            options: 'key': 'value'
          'service_a':
            module: "#{tmp}/a"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
            deps: 'my_dep_a': module: "#{tmp}/dep_a", single: true
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
          'c.fqdn': ip: '10.10.10.3'
    ).should.throw 'Invalid Option: single only apply to 1 dependencies, found 3'
