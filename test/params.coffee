
import fs from 'node:fs/promises'
import { Writable } from 'node:stream'
import nikita from 'nikita'
import masson from 'masson'

describe 'params', ->

  it 'can be overwritten from configuration', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      data = null
      stderr = new Writable
        write: (d) -> data = d.toString()
      await fs.writeFile "#{tmpdir}/config.json", JSON.stringify
        params: commands: 'help': description: 'Overwrite default description'
      await masson ['-c', "#{tmpdir}/config.json", 'help'], router: stderr: stderr
      data.split(/\r\n|[\n\r\u0085\u2028\u2029]/g)
      .should.containEql '  help                      Overwrite default description'
