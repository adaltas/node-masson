
normalize = require '../../lib/config/normalize'
params = require '../../lib/params'
fs = require 'fs'
nikita = require 'nikita'
parameters = require 'parameters'

describe 'command graph', ->
  
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

  it 'no arguments', ->
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
    parameters(params).run(['graph', '-f', 'json'], config)
    process.stdout.write = write
    JSON.parse(data).should.eql [
      'cluster_a:dep_a'
      'cluster_a:service_a'
    ]

  it 'with nodes', ->
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
    parameters(params).run(['graph', '--nodes', '-f', 'json'], config)
    process.stdout.write = write
    JSON.parse(data).should.eql [
      cluster: 'cluster_a'
      id: 'dep_a'
      module: "#{tmp}/a"
      nodes: []
    ,
      cluster: 'cluster_a'
      id: 'service_a'
      module: "#{tmp}/a"
      nodes: []
    ]
