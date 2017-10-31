
normalize = require '../../lib/config/normalize'
affinity = require '../../lib/config/affinities'
store = require '../../lib/config/store'
fs = require 'fs'
nikita = require 'nikita'

describe 'affinity tags', ->

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

  describe 'normalize', ->
    
    it 'single tag, tag value as string, single array or single object', ->
      affinity.handlers.tags.normalize
        type: 'tags', values: 'tag_a': 'value_a'
      .should.eql
        type: 'tags', values: 'tag_a': values: 'value_a': true
      affinity.handlers.tags.normalize
        type: 'tags', values: 'tag_a': ['value_a']
      .should.eql
        type: 'tags', values: 'tag_a': values: 'value_a': true
      affinity.handlers.tags.normalize
        type: 'tags', values: 'tag_a': values: 'value_a': true
      .should.eql
        type: 'tags', values: 'tag_a': values: 'value_a': true
    
    it 'ensure match is present if multiple tags', ->
      ( ->
        affinity.handlers.tags.normalize
          type: 'tags', values:
            'tag_a': 'value_a'
            'tag_b': 'value_b'
      ).should.throw 'Required Property: "match", when more than one tag'
    
    it 'ensure match is present if multiple values', ->
      ( ->
        affinity.handlers.tags.normalize
          type: 'tags', values: 'tag_a': ['value_a', 'value_b']
      ).should.throw 'Required Property: "match", when more than one value'
      ( ->
        affinity.handlers.tags.normalize
          type: 'tags', values: 'tag_a': values: 'value_a': true, 'value_b': true
      ).should.throw 'Required Property: "match", when more than one value'
      
    it 'multiple tags', ->
      affinity.handlers.tags.normalize
        type: 'tags', match: 'all', values:
          'tag_a': 'value_a'
          'tag_b': 'value_b'
      .should.eql
        type: 'tags', match: 'all', values:
          'tag_a': values: 'value_a': true
          'tag_b': values: 'value_b': true
          
    it 'multiple values', ->
      affinity.handlers.tags.normalize
        type: 'tags', values: 'tag_a':
          match: 'any'
          values: ['value_a', 'value_b']
      .should.eql
        type: 'tags', values: 'tag_a':
          match: 'any'
          values:
            'value_a': true
            'value_b': true

  describe 'resolve', ->
    
    it 'match single tag', ->
      fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
      s = store normalize
        clusters: 'cluster_a': services: 'service_a':
          module: "#{tmp}/a"
          affinity:
            type: 'tags'
            values: 'role': values: 'master': true
        nodes:
          'a.fqdn': tags:
            'role': ['master', 'worker']
          'b.fqdn': tags:
            'role': 'client'
      affinity.handlers.tags.resolve s.config(),
        s.service('cluster_a', 'service_a').affinity[0]
      .should.eql ['a.fqdn']
        
    it 'match all tag', ->
      fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
      s = store normalize
        clusters: 'cluster_a': services: 'service_a':
          module: "#{tmp}/a"
          affinity:
            type: 'tags'
            match: 'all'
            values:
              'role': 'master'
              'env': 'prod'
        nodes:
          'a.fqdn': tags: 'env': 'prod', 'role': ['master', 'worker']
          'b.fqdn': tags: 'env': 'prod', 'role': 'client'
          'c.fqdn': tags: 'env': 'dev', 'role': 'client'
          'd.fqdn': tags: 'env': 'dev', 'role': 'master'
      affinity.handlers.tags.resolve s.config(),
        s.service('cluster_a', 'service_a').affinity[0]
      .should.eql ['a.fqdn']
        
    it 'match any tag', ->
      fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
      s = store normalize
        clusters: 'cluster_a': services: 'service_a':
          module: "#{tmp}/a"
          affinity:
            type: 'tags'
            match: 'any'
            values:
              'role': 'master'
              'env': 'prod'
        nodes:
          'a.fqdn': tags: 'env': 'prod', 'role': ['master', 'worker']
          'b.fqdn': tags: 'env': 'prod', 'role': 'client'
          'c.fqdn': tags: 'env': 'dev', 'role': 'client'
          'd.fqdn': tags: 'env': 'dev', 'role': 'master'
      affinity.handlers.tags.resolve s.config(),
        s.service('cluster_a', 'service_a').affinity[0]
      .should.eql ['a.fqdn', 'b.fqdn', 'd.fqdn']
        
    it 'match none tag', ->
      fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
      s = store normalize
        clusters: 'cluster_a': services: 'service_a':
          module: "#{tmp}/a"
          affinity:
            type: 'tags'
            match: 'none'
            values:
              'role': 'master'
              'env': 'prod'
        nodes:
          'a.fqdn': tags: 'env': 'prod', 'role': ['master', 'worker']
          'b.fqdn': tags: 'env': 'prod', 'role': 'client'
          'c.fqdn': tags: 'env': 'dev', 'role': 'client'
          'd.fqdn': tags: 'env': 'dev', 'role': 'master'
      affinity.handlers.tags.resolve s.config(),
        s.service('cluster_a', 'service_a').affinity[0]
      .should.eql ['c.fqdn']
