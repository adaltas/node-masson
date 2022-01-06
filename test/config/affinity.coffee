
normalize = require '../../lib/config/normalize'
affinity = require '../../lib/config/affinities'
store = require '../../lib/config/store'
fs = require 'fs'
nikita = require 'nikita'

describe 'affinity', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
  
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
