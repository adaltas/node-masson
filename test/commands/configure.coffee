
normalize = require '../../lib/config/normalize'
params = require '../../lib/params'
fs = require 'fs'
nikita = require 'nikita'
parameters = require 'parameters'

describe 'command configure', ->
  
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
      
  it 'format json', ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    config = normalize
      clusters:
        'cluster_a':
          services:
            "#{tmp}/a": true
    parameters(params).route(['configure', '--format', 'json'], config)
    process.stdout.write = write
    JSON.parse(data).should.eql config

  it 'cluster', ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    config = normalize
      clusters:
        'cluster_a':
          services:
            "#{tmp}/a": true
        'cluster_b': {}
    parameters(params).route(['configure', '--cluster', 'cluster_a', '-f', 'json'], config)
    process.stdout.write = write
    JSON.parse(data).should.eql
      id: "cluster_a"
      services:
        "/tmp/masson-test/a":
          affinity: []
          cluster: "cluster_a"
          commands: {}
          deps: {}
          id: "/tmp/masson-test/a"
          module: "/tmp/masson-test/a"
          instances: []
          nodes: {}

  it 'service', ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    config = normalize
      clusters: 'cluster_a': services:
        'dep_a':
          module: "#{tmp}/a"
          options: 'key': 'value'
        'service_a':
          module: "#{tmp}/a"
          deps: 'my_dep_a': module: "#{tmp}/dep_a", local: true
    parameters(params).route(['configure', '--cluster', 'cluster_a', '--service', 'service_a', '-f', 'json'], config)
    process.stdout.write = write
    JSON.parse(data).id.should.eql 'service_a'

  it 'nodes', ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    config = normalize
      clusters: 'cluster_a': services:
        'service_a':
          module: "#{tmp}/a"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2'
        'c.fqdn': ip: '10.10.10.3'
    parameters(params).route(['configure', '--nodes', '-f', 'json'], config)
    process.stdout.write = write
    JSON.parse(data)
    .map (node) -> node.id
    .should.eql ['a.fqdn', 'b.fqdn', 'c.fqdn']

  it 'node', ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
    fs.writeFileSync "#{tmp}/dep_a.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    config = normalize
      clusters: 'cluster_a': services:
        'service_a':
          module: "#{tmp}/a"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2'
        'c.fqdn': ip: '10.10.10.3'
    parameters(params).route(['configure', '--node', 'c.fqdn', '-f', 'json'], config)
    process.stdout.write = write
    JSON.parse(data).should.eql
      ip: "10.10.10.3",
      id: "c.fqdn",
      fqdn: "c.fqdn",
      hostname: "c",
      services: [
        cluster: "cluster_a", service: "service_a", module: "#{tmp}/a"
      ]
