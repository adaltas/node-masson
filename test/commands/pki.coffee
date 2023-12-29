
import fs from 'node:fs/promises'
import { Writable } from 'node:stream'
import normalize from 'masson/config/normalize'
import params from 'masson/params'
import nikita from 'nikita'
import {shell} from 'shell'

describe 'command pki', ->

  it 'CA generate', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      data = null
      stdout = new Writable
        write: (d) -> data = d.toString()
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      config = await normalize {}
      await shell({...params, router: stdout: stdout}).route ['pki', '--dir', "#{tmpdir}", 'ca'], config
      data.should.eql """
      
      Certificate files generated:
      * Key: "#{tmpdir}/ca.key.pem"
      * Certificate: "#{tmpdir}/ca.cert.pem"
      * Subject: "/C=FR/O=Adaltas/L=Paris/CN=adaltas.com"
      
      
      """
