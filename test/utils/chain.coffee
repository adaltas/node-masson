
import fs from 'node:fs/promises'
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

describe 'chain', ->
  
  it 'chain/unchain', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      await fs.writeFile "#{tmpdir}/b.json", JSON.stringify {}
      store await normalize
        clusters: 'cluster_a': services:
          'service_a':
            module: "#{tmpdir}/a.json"
          'service_b':
            module: "#{tmpdir}/b.json"
      .chain()
      .service 'cluster_a', 'service_a', (service) ->
        service.id.should.eql 'service_a'
      .service 'cluster_a', 'service_b', (service) ->
        service.id.should.eql 'service_b'
      .unchain()
      .service 'cluster_a', 'service_a'
      .id
      .should.eql 'service_a'
