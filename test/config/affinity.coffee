
import normalize from 'masson/config/normalize'
import affinity from 'masson/config/affinities'
import store from 'masson/config/store'
import fs from 'fs'
import nikita from 'nikita'

describe 'affinity', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
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
