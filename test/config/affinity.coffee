
import fs from 'node:fs'
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import affinity from 'masson/config/affinities'
import store from 'masson/config/store'

describe 'affinity', ->
  
  describe 'complete', ->
  
    it 'accept no values', ->
      config = 
        cluster:
          name: 'cluster_a'
          services:
            'module/a': true
        nodes:
          'fqdn_a': true
      config = await normalize config
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
      config = await normalize config
      nodes = affinity.nodes config, 'service_a'
      nodes.should.eql []
      services = affinity.services config, 'fqdn_a'
      services.should.eql []
