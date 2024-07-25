
import nikita from '@nikitajs/core'
import registry from '@nikitajs/core/registry'
import '@nikitajs/file/register'
import normalize from '../../lib/config/normalize.js'
import mklayout from '../../lib/utils/mklayout.js'

describe 'config.normalize', ->

  describe 'nodes', ->

    it 'name default to key', ->
      normalize
        nodes:
          node_1: {}
          node_2: {}
      .then ({nodes}) -> nodes
      .should.finally.eql [
          { name: "node_1", config: { hostname: undefined } },
          { name: "node_2", config: { hostname: undefined } }
        ]

  describe 'masson.nikita', ->

    it 'default normalization', ->
      normalize() 
      .then((config) => config.masson.nikita)
      .should.finally.eql { $: false }

  describe 'masson.register', ->

    it 'load module when defined as string', ->
      mklayout([
        ['./package.json', { type: 'module'}],
        ['./register.js', '''
        // Dependencies
        import registry from "@nikitajs/core/registry";

        // Action registration
        await registry.register({
          masson_test: "{{tmpdir}}/test.js",
        });

        '''],
        ['./test.js', 'export default () => "ok"'],
      ], (tmpdir) ->
        await normalize
          masson:
            register: ["#{tmpdir}/register.js"]
        actions = await registry.get()
        actions.masson_test[''].metadata.module.should.eql "#{tmpdir}/test.js"
      )

    it 'merge with the nikita default action when an object', ->
      normalize
        masson:
          register: [{
            "an": "action": (->)
          }]
      .then((config) => config.masson.nikita.metadata.register)
      .should.finally.eql "an": "action": (->)

  describe 'actions', ->

    it 'root actions no children', ->
      normalize
        actions:
          action_1: {}
          action_2: {}
      .then ({actions}) -> actions.map ({actions, masson, metadata}) -> ({actions, masson, metadata})
      .should.finally.eql [
        actions: []
        masson: { name: 'action_1', namespace: ['action_1'], "slug": '/action_1' }
        metadata: { header: [] }
      ,
        actions: []
        masson: { name: 'action_2', namespace: ['action_2'], "slug": '/action_2' }
        metadata: { header: [] }
      ]

    it 'deep actions', ->
      normalize
        actions:
          action_1:
            actions:
              action_1_1:
                actions:
                  action_1_1_1: {}
          action_2:
            actions:
              action_2_1: {}
      .then ({actions}) -> actions.map ({actions, masson, metadata}) -> ({actions, masson, metadata})
      .should.finally.eql [
        actions: [ [ 'action_1', 'action_1_1' ] ]
        masson: { name: 'action_1', namespace: ['action_1'], slug: '/action_1' }
        metadata: { header: [] }
      ,
        actions: [ [ 'action_1', 'action_1_1', 'action_1_1_1' ] ]
        masson: { name: 'action_1_1', namespace: ['action_1', 'action_1_1'], slug: '/action_1/action_1_1' }
        metadata: { header: [] }
      ,
        actions: []
        masson: { name: 'action_1_1_1', namespace: ['action_1', 'action_1_1', 'action_1_1_1'], slug: '/action_1/action_1_1/action_1_1_1' }
        metadata: { header: [] }
      ,
        actions: [ [ 'action_2', 'action_2_1' ] ]
        masson: { name: 'action_2', namespace: ['action_2'], slug: '/action_2' }
        metadata: { header: [] }
      ,
        actions: []
        masson: { name: 'action_2_1', namespace: ['action_2', 'action_2_1'], slug: '/action_2/action_2_1' }
        metadata: { header: [] }
      ]

  describe 'actions.nodes', ->

    it 'not defined', ->
      normalize
        nodes:
          node_1: config: hostname: 'node_1'
          node_2 : {}
        actions:
          action_1: {} 
      .then ({actions}) -> actions.shift()
      .then ({nodes}) -> nodes
      .should.finally.eql []
    
    it 'string match all', ->
      normalize
        nodes:
          node_1: config: hostname: 'node_1'
          node_2 : {}
        actions:
          action_1:
            nodes: '*'
      .then ({actions}) -> actions.shift()
      .then (action) -> action.nodes.should.eql ['node_1', 'node_2']
    
    it 'array match nodes.<node>.name and nodes.<node>.config.[hostname,fqdn]', ->
      normalize
        nodes:
          node_1: config: hostname: 'node_1'
          node_2: config: fqdn: 'node_2.domain.com'
          node_3: {}
          invalid_node: {}
        actions:
          action_1:
            nodes: ['node_*']
      .then ({actions}) -> actions.shift()
      .then (action) -> action.nodes.should.eql ['node_1', 'node_2', 'node_3']
