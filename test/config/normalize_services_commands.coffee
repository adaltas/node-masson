
import fs from 'node:fs/promises'
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

describe 'normalize service commands', ->
  
  it 'take an array of string and function', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      store await normalize
        clusters: 'cluster_a': services:
          'service_a': module: "#{tmpdir}/a.json", commands:
            my_command: [
              "#{tmpdir}/a.json",
              (->)
            ]
      .service 'cluster_a', 'service_a'
      .commands.my_command.should.eql [
        "#{tmpdir}/a.json",
        (->)
      ]
  
  it 'convert string and function to function', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      store await normalize
        clusters: 'cluster_a': services:
          'service_a': module: "#{tmpdir}/a.json", commands:
            my_string: "#{tmpdir}/a.json"
            my_function: (->)
      .service 'cluster_a', 'service_a'
      .commands.should.eql
        my_string: [ "#{tmpdir}/a.json" ]
        my_function: [(->)]
    
  it 'accept only array, string and function', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      await normalize
        clusters: 'cluster_a': services:
          'service_a': module: "#{tmpdir}/a.json", commands:
            my_null: null
      .should.be.rejectedWith 'Invalid Command: accept array, string or function, got null for command "my_null"'
      await normalize
        clusters: 'cluster_a': services:
          'service_a': module: "#{tmpdir}/a.json", commands:
            my_null: 123
      .should.be.rejectedWith 'Invalid Command: accept array, string or function, got 123 for command "my_null"'
