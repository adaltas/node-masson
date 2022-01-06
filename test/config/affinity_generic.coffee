
normalize = require '../../lib/config/normalize'
affinity = require '../../lib/config/affinities'
store = require '../../lib/config/store'
fs = require 'fs'
nikita = require 'nikita'

describe 'affinity generic', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
  
  describe 'normalize', ->
  
    it 'minimal', ->
      affinity.handlers.generic.normalize
        match: 'all'
        values: []
      .should.eql
        type: 'generic'
        match: 'all'
        values: []
          
    it 'validate properties', ->
      ( ->
        affinity.handlers.generic.normalize
          match: 'all'
      ).should.throw 'Required Property: "values" not found'
      ( ->
        affinity.handlers.generic.normalize
          match: 'all'
          values: {}
      ).should.throw 'Invalid Property: "values" not an array'
      
    it 'multiple affinities', ->
      affinity.handlers.generic.normalize
        match: 'all', values:[
          type: 'tags', values: 'role': 'master'
        ,
          type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn']
        ]
      .should.eql
        type: 'generic', match: 'all', values: [
          type: 'tags', values: 'role': values: 'master': true
        ,
          type: 'nodes', match: 'any', values: 'a.fqdn': true, 'b.fqdn': true
        ]

  describe 'resolve', ->

    it 'match all', ->
      fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
      store normalize
        clusters: 'cluster_a': services: 'service_a':
          module: "#{tmp}/a"
          affinity:
            match: 'all'
            values: [
              type: 'tags'
              values: 'role': 'master'
            ,
              type: 'nodes'
              match: 'any'
              values: ['a.fqdn', 'b.fqdn']
            ]
        nodes:
          'a.fqdn': tags: 'env': 'prod', 'role': ['master', 'worker']
          'b.fqdn': tags: 'env': 'prod', 'role': 'client'
          'c.fqdn': tags: 'env': 'dev', 'role': 'client'
          'd.fqdn': tags: 'env': 'dev', 'role': 'master'
      .chain()
      .service 'cluster_a', 'service_a', (service) ->
        service.instances
        .map (instance) -> instance.node.id
        .should.eql ['a.fqdn']

    it 'match any', ->
      fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
      store normalize
        clusters: 'cluster_a': services: 'service_a':
          module: "#{tmp}/a"
          affinity:
            match: 'any'
            values: [
              type: 'tags'
              values: 'role': 'master'
            ,
              type: 'nodes'
              match: 'any'
              values: ['a.fqdn', 'b.fqdn']
            ]
        nodes:
          'a.fqdn': tags: 'env': 'prod', 'role': ['master', 'worker']
          'b.fqdn': tags: 'env': 'prod', 'role': 'client'
          'c.fqdn': tags: 'env': 'dev', 'role': 'client'
          'd.fqdn': tags: 'env': 'dev', 'role': 'master'
      .chain()
      .service 'cluster_a', 'service_a', (service) ->
        service.instances
        .map (instance) -> instance.node.id
        .should.eql ['a.fqdn', 'b.fqdn', 'd.fqdn']
  
