
    module.exports = (nodes, constraints) ->
      filter = {}
      nodes = for id, node of nodes then node
      nodes.filter (node) ->
        return true if constraints.nodes[node.id]
        for tag, value of constraints.tags
          return true if value[node.tags[tag]]
