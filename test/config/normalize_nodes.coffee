
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

describe 'normalize nodes', ->
  
  it 'value is true', ->
    store await normalize
      nodes:
        'a.fqdn': true
    .node 'a.fqdn'
    .should.eql
      id: 'a.fqdn'
      fqdn: 'a.fqdn'
      hostname: 'a'
      services: []
