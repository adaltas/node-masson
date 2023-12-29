
import fs from 'node:fs/promises'
import { Writable } from 'node:stream'
import nikita from 'nikita'
import {shell} from 'shell'
import normalize from 'masson/config/normalize'
import params from 'masson/params'

describe 'command graph', ->

  it 'no arguments', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      data = null
      stdout = new Writable
        write: (d) -> data = d.toString()
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      config = await normalize
        clusters: 'cluster_a': services:
          'dep_a':
            module: "#{tmpdir}/a.json"
            options: 'key': 'value'
          'service_a':
            module: "#{tmpdir}/a.json"
            deps: 'my_dep_a': module: "#{tmpdir}/dep_a.json", local: true
      await shell({...params, router: stdout: stdout}).route(['graph', '-f', 'json'], config)
      JSON.parse(data).should.eql [
        'cluster_a:dep_a'
        'cluster_a:service_a'
      ]

  it 'with nodes, JSON format', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      data = null
      stdout = new Writable
        write: (d) -> data = d.toString()
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      config = await normalize
        clusters: 'cluster_a': services:
          'dep_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', values: 'b.fqdn'
            options: 'key': 'value'
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', values: 'a.fqdn'
            deps: 'my_dep_a': module: "#{tmpdir}/dep_a.json", local: true
        nodes:
          'a.fqdn': true
          'b.fqdn': true
      await shell({...params, router: stdout: stdout}).route(['graph', '--nodes', '-f', 'json'], config)
      JSON.parse(data).should.eql [
        cluster: 'cluster_a'
        id: 'dep_a'
        module: "#{tmpdir}/a.json"
        nodes: ['b.fqdn']
      ,
        cluster: 'cluster_a'
        id: 'service_a'
        module: "#{tmpdir}/a.json"
        nodes: ['a.fqdn']
      ]

  it 'with nodes, human format', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      data = null
      stdout = new Writable
        write: (d) -> data = d.toString()
      await fs.writeFile "#{tmpdir}/dep_a.json", JSON.stringify {}
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      config = await normalize
        clusters: 'cluster_a': services:
          "#{tmpdir}/dep_a.json":
            affinity: type: 'nodes', values: 'b.fqdn'
            options: 'key': 'value'
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', values: 'a.fqdn'
            deps: 'my_dep_a': module: "#{tmpdir}/dep_a.json", local: true
        nodes:
          'a.fqdn': true
          'b.fqdn': true
      await shell({...params, router: stdout: stdout}).route(['graph', '--nodes'], config)
      data.substr(-2, 2).should.eql '\n\n'
      data.trim().should.eql """
      * cluster_a:#{tmpdir}/dep_a.json
        * b.fqdn
      
      * cluster_a:service_a (#{tmpdir}/a.json)
        * a.fqdn
      """
