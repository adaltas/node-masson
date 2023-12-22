
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'
import nikita from 'nikita'
import fs from 'fs'

describe 'normalize services', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
  
  it 'value is true', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    store normalize
      clusters:
        'cluster_a':
          services:
            "#{tmp}/a": true
    .service 'cluster_a', "#{tmp}/a"
    .should.eql
      id: "#{tmp}/a"
      cluster: 'cluster_a'
      module: "#{tmp}/a"
      affinity: []
      deps: {}
      commands: {}
      instances: []
      nodes: {}
        
  it 'module is string', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    store normalize
      clusters:
        'cluster_a':
          services:
            'service_a':
              module: "#{tmp}/a"
    .service 'cluster_a', 'service_a'
    .should.eql
      id: 'service_a'
      cluster: 'cluster_a'
      module: "#{tmp}/a"
      affinity: []
      deps: {}
      commands: {}
      instances: []
      nodes: {}
  
