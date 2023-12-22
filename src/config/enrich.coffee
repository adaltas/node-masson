
export default (config) ->
  # Enrich configuration
  for cname, cluster of config.clusters
    for sname, service of cluster.services
      # Load configuration
      if service.configure
        service.configure = load service.configure if typeof service.configure is 'string'
        throw Error "Invalid Configuration: not a function, got #{typeof service.configure}" unless typeof service.configure is 'function'
      for _, node of config.nodes
        service.configure.call null,
          use: service.deps
          options: service.config
          node: node
  
