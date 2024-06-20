
import nikita from '@nikitajs/core'
import '@nikitajs/file/register'
import discover from '../../lib/config/discover.js'

describe 'config.discover', ->

  describe 'structure', ->

    it 'load composite filenames', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await @file.yaml
          target: "#{tmpdir}/conf/actions.service.actions.component_1.yml"
          content: config: test: 'test 1'
        await @file.yaml
          target: "#{tmpdir}/conf/actions.service.actions.component_2.yaml"
          content: config: test: 'test 2'
        discover searchs: "#{tmpdir}/conf"
          .should.finally.eql
            actions: service: actions:
              component_1: config: test: 'test 1'
              component_2: config: test: 'test 2'

    it 'load composite directories', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await @file.yaml
          target: "#{tmpdir}/conf/actions.service.actions/component_1.yml"
          content: config: test: 'test 1'
        await @file.yaml
          target: "#{tmpdir}/conf/actions.service.actions/component_2.yaml"
          content: config: test: 'test 2'
        await discover searchs: "#{tmpdir}/conf"
          .should.finally.eql
            actions: service: actions:
              component_1: config: test: 'test 1'
              component_2: config: test: 'test 2'
  
  describe 'load', ->

    it 'yaml', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await @file.yaml
          target: "#{tmpdir}/conf/actions.yml"
          content: component_1: config: test: 'test 1'
        await discover searchs: "#{tmpdir}/conf"
          .should.finally.eql
            actions:
              component_1: config: test: 'test 1'

    it 'js ESM', ->
      nikita
        $tmpdir: true
        $dirty: true
      , ({metadata: {tmpdir}}) ->
        await @file.json
          target: "#{tmpdir}/package.json"
          content: type: 'module'
        await @file
          target: "#{tmpdir}/conf/actions.js"
          content: '''
          export default { component_1: { config: { test: 'test 1' } } }
          '''
        await discover searchs: "#{tmpdir}/conf"
          .should.finally.eql
            actions:
              component_1: config: test: 'test 1'

    it 'js CommonJS', ->
      nikita
        $tmpdir: true
        $dirty: true
      , ({metadata: {tmpdir}}) ->
        await @file
          target: "#{tmpdir}/conf/actions.js"
          content: '''
          module.exports = { component_1: { config: { test: 'test 1' } } }
          '''
        await discover searchs: "#{tmpdir}/conf"
          .should.finally.eql
            actions:
              component_1: config: test: 'test 1'

    it 'json', ->
      nikita
        $tmpdir: true
        $dirty: true
      , ({metadata: {tmpdir}}) ->
        await @file.json
          target: "#{tmpdir}/conf/actions.json"
          content: component_1: config: test: 'test 1'
        await discover searchs: "#{tmpdir}/conf"
          .should.finally.eql
            actions:
              component_1: config: test: 'test 1'
