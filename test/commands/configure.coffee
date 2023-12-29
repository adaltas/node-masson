
import fs from 'node:fs/promises'
import normalize from 'masson/config/normalize'
import params from 'masson/params'
import nikita from 'nikita'
import {shell} from 'shell'

describe 'command configure', ->
  
  tmp = '/tmp/masson-test'
  beforeEach ->
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
  
  it 'format json', ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
    await fs.writeFile "#{tmp}/a.json", JSON.stringify {}
    config = await normalize
      clusters:
        'cluster_a':
          services:
            "#{tmp}/a.json": true
    await shell(params).route(['configure', '--format', 'json'], config)
    process.stdout.write = write
    JSON.parse(data).should.eql config

  it 'cluster', ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
    await fs.writeFile "#{tmp}/a.json", JSON.stringify {}
    config = await normalize
      clusters:
        'cluster_a':
          services:
            "#{tmp}/a.json": true
        'cluster_b': {}
    await shell(params).route(['configure', '--cluster', 'cluster_a', '-f', 'json'], config)
    process.stdout.write = write
    JSON.parse(data).should.eql
      id: "cluster_a"
      services:
        "#{tmp}/a.json":
          affinity: []
          cluster: "cluster_a"
          commands: {}
          deps: {}
          id: "#{tmp}/a.json"
          module: "#{tmp}/a.json"
          instances: []
          nodes: {}

  it 'service', ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
    await fs.writeFile "#{tmp}/a.json", JSON.stringify {}
    config = await normalize
      clusters: 'cluster_a': services:
        'dep_a':
          module: "#{tmp}/a.json"
          options: 'key': 'value'
        'service_a':
          module: "#{tmp}/a.json"
          deps: 'my_dep_a': module: "#{tmp}/dep_a", local: true
    await shell(params).route(['configure', '--cluster', 'cluster_a', '--service', 'service_a', '-f', 'json'], config)
    process.stdout.write = write
    JSON.parse(data).id.should.eql 'service_a'

  it 'nodes', ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
    await fs.writeFile "#{tmp}/dep_a.json", JSON.stringify {}
    await fs.writeFile "#{tmp}/a.json", JSON.stringify {}
    config = await normalize
      clusters: 'cluster_a': services:
        'service_a':
          module: "#{tmp}/a.json"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2'
        'c.fqdn': ip: '10.10.10.3'
    await shell(params).route(['configure', '--nodes', '-f', 'json'], config)
    process.stdout.write = write
    JSON.parse(data)
    .map (node) -> node.id
    .should.eql ['a.fqdn', 'b.fqdn', 'c.fqdn']

  it 'node', ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
    await fs.writeFile "#{tmp}/dep_a.json", JSON.stringify {}
    await fs.writeFile "#{tmp}/a.json", JSON.stringify {}
    config = await normalize
      clusters: 'cluster_a': services:
        'service_a':
          module: "#{tmp}/a.json"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2'
        'c.fqdn': ip: '10.10.10.3'
    await shell(params).route(['configure', '--node', 'c.fqdn', '-f', 'json'], config)
    process.stdout.write = write
    JSON.parse(data).should.eql
      ip: "10.10.10.3",
      id: "c.fqdn",
      fqdn: "c.fqdn",
      hostname: "c",
      services: [
        cluster: "cluster_a", service: "service_a", module: "#{tmp}/a.json"
      ]
