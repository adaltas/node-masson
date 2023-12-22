
import normalize from 'masson/config/normalize'
import affinity from 'masson/config/affinities'
import store from 'masson/config/store'
import fs from 'fs'
import nikita from 'nikita'

describe 'affinity services', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
    
  describe 'normalize', ->
  
    it 'values as string', ->
      affinity.handlers.services.normalize
        type: 'services', values: 'service/a'
      .should.eql
        type: 'services', values: 'service/a': true
            
    it 'values as array', ->
      affinity.handlers.services.normalize
        type: 'services',  values: ['service/a']
      .should.eql
        type: 'services', values: 'service/a': true
            
    it 'values as object', ->
      affinity.handlers.services.normalize
        type: 'services', values: {'service/a': true}
      .should.eql
        type: 'services', values: 'service/a': true
