
multimatch = require '../utils/multimatch'
chain = require '../utils/chain'
flatten = require '../utils/flatten'
unique = require '../utils/unique'

module.exports = (config) ->
  chain
    config: ->
      config
    cluster: (cluster) ->
      config.clusters[cluster] or null
    cluster_names: (match=null) ->
      flatten Object.keys(config.clusters).map (cluster) ->
        if match
        then multimatch cluster, match
        else cluster
    service: (cluster, service) ->
      [cluster, service] = arguments[0].split ':' if arguments.length is 1
      throw Error "Invalid Argument: cluster is required, got #{JSON.stringify cluster}" unless cluster
      throw Error "Invalid Argument: service is required, got #{JSON.stringify service}" unless service
      cluster = @cluster cluster
      return null unless cluster
      cluster.services[service] or null
    service_names: (match='*:**') ->
      [cmatch, smatch] = match.split ':'
      [smatch, cmatch] = [cmatch, smatch] unless /:/.test match
      cmatch = '*' unless cmatch
      smatch = '**' unless smatch
      flatten Object.values(config.clusters).map (cluster) ->
        return [] unless multimatch(cluster.id, cmatch).length
        Object.values(cluster.services).map (service) ->
          multimatch service.id, smatch
          .map (name) -> "#{cluster.id}:#{name}"
    service_deps: (cluster, service) ->
      for _, dservice of service.use
        # Find by ID or by name
        @service(dservice.id)
    nodes: ->
      Object.values config.nodes
    node: (node) ->
      config.nodes[node] or null
    commands: ->
      unique flatten Object.values(config.clusters).map (cluster) ->
        Object.values(cluster.services).map (service) ->
          Object.keys service.commands 
