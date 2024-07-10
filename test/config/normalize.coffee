
import nikita from '@nikitajs/core'
import '@nikitajs/file/register'
import normalize from '../../lib/config/normalize.js'

describe 'config.normalize', ->

  describe 'nodes', ->

    it 'name default to key', ->
      normalize
        nodes:
          node_1: {}
          node_2: {}
      .should.eql 
        nodes: [
          { name: "node_1", config: { hostname: undefined } },
          { name: "node_2", config: { hostname: undefined } }
        ],
        actions: []

  describe 'actions', ->

    it 'root actions no children', ->
      normalize
        actions:
          action_1: {}
          action_2: {}
      .should.eql
        actions: [
          { masson: { name: 'action_1', namespace: ['action_1'], "slug": '/action_1' }, metadata: { header: [] } }
          { masson: { name: 'action_2', namespace: ['action_2'], "slug": '/action_2' }, metadata: { header: [] } }
        ]
        nodes: []

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
      .should.eql
        actions: [
          { masson: { name: 'action_1', namespace: ['action_1'], slug: '/action_1' }, metadata: { header: [] } }
          { masson: { name: 'action_1_1', namespace: ['action_1', 'action_1_1'], slug: '/action_1/action_1_1' }, metadata: { header: [] } }
          { masson: { name: 'action_1_1_1', namespace: ['action_1', 'action_1_1', 'action_1_1_1'], slug: '/action_1/action_1_1/action_1_1_1' }, metadata: { header: [] } }
          { masson: { name: 'action_2', namespace: ['action_2'], slug: '/action_2' }, metadata: {header: []} }
          { masson: { name: 'action_2_1', namespace: ['action_2', 'action_2_1'], slug: '/action_2/action_2_1' }, metadata: { header: [] } }
        ]
        nodes: []
