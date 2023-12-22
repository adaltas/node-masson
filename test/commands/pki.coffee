
import normalize from 'masson/config/normalize'
import params from 'masson/params'
import fs from 'fs/promises'
import nikita from 'nikita'
import {shell} from 'shell'

describe 'command pki', ->
  
  tmp = '/tmp/masson-test'
  beforeEach ->
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true

  it 'CA generate', ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
      true
    await fs.writeFile "#{tmp}/a.json", JSON.stringify {}
    config = normalize {}
    await shell(params).route ['pki', '--dir', "#{tmp}", 'ca'], config
    process.stdout.write = write
    data.should.eql """
    
    Certificate files generated:
    * Key: "/tmp/masson-test/ca.key.pem"
    * Certificate: "/tmp/masson-test/ca.cert.pem"
    * Subject: "/C=FR/O=Adaltas/L=Paris/CN=adaltas.com"
    
    
    """
