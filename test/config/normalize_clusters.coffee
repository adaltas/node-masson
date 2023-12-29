
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

describe 'normalize clusters', ->
    
  it 'validate root elements', ->
    normalize clusters: true
    .should.be.rejectedWith 'Invalid Clusters: expect an object, got true'
  
  it 'value is true', ->
    store await normalize clusters: 'cluster_a': true
    .cluster 'cluster_a'
    .should.eql
      id: 'cluster_a'
      services: {}
  
