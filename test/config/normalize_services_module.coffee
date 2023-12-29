
import fs from 'node:fs/promises'
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

describe 'normalize service module', ->
  
  it 'merge module definition', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify
        my_property: true
      res = store await normalize
        clusters: 'cluster_a': services: 'service_a': module: "#{tmpdir}/a.json"
      .service 'cluster_a', 'service_a'
      .my_property
      .should.be.true()

  it 'ensure object type', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/invalid_type.js", 'module.exports = function(){}'
      await normalize
        clusters: 'cluster_a': services: 'service_a': module: "#{tmpdir}/invalid_type.js"
      .should.be.rejectedWith "Invalid Service Definition: expect an object for module \"#{tmpdir}/invalid_type.js\", got \"function\""

  it 'catch invalid syntax', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/invalid_syntax.js", 'module.exports = this is messed up'
      await normalize
        clusters: 'cluster_a': services: 'service_a': module: "#{tmpdir}/invalid_syntax.js"
      .should.be.rejectedWith "Unexpected identifier 'is'"
