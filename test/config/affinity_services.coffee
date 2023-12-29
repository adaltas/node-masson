
import nikita from 'nikita'
import affinity from 'masson/config/affinities'

describe 'affinity services', ->
    
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
