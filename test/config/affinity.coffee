
normalize = require '../../lib/config/normalize'
affinity = require '../../lib/config/affinities'
store = require '../../lib/config/store'
fs = require 'fs'
nikita = require 'nikita'

describe 'affinity', ->

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
  
  describe 'complete', ->
  
    it 'accept no values', ->
      config = 
        cluster:
          name: 'cluster_a'
          services:
            'module/a': true
        nodes:
          'fqdn_a': true
      config = normalize config
      nodes = affinity.nodes config, 'service_a'
      nodes.should.eql []
      services = affinity.services config, 'fqdn_a'
      services.should.eql []
      
    it 'false if no values', ->
      config = 
        cluster:
          name: 'cluster_a'
          services:
            'module/a':
              affinity:
                match: 'all'
        nodes:
          'fqdn_a': true
      config = normalize config
      nodes = affinity.nodes config, 'service_a'
      nodes.should.eql []
      services = affinity.services config, 'fqdn_a'
      services.should.eql []
