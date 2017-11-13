
tsort = require 'tsort'
{merge} = require 'nikita/lib/misc'
load = require '../utils/load'
affinities = require './affinities'

module.exports = (config) ->
  if config.clusters? and not is_object config.clusters
    throw Error "Invalid Clusters: expect an object, got #{JSON.stringify config.clusters}"
  if config.services? and not is_object config.services
    throw Error "Invalid Services: expect an object, got #{JSON.stringify config.services}"
  if config.nodes? and not is_object config.nodes
    throw Error "Invalid Nodes: expect an object, got #{JSON.stringify config.nodes}"
  config.clusters ?= {}
  config.nodes ?= {}
  discover_service = (cname, sname, service)->
    service = config.clusters[cname].services[sname] = {} if service is true
    service.module ?= sname
    # Load service module
    externalModDef = load service.module
    throw Error "Invalid Service Definition: expect an object for module #{JSON.stringify service.module}, got #{JSON.stringify typeof externalModDef}" unless is_object externalModDef
    merge service, externalModDef
    # Define auto loaded services
    service.deps ?= {}
    for dname, dservice of service.deps
      dservice = service.deps[dname] = module: dservice if typeof dservice is 'string'
      # Id
      if dservice.service
      then [did, dcluster] = dservice.service.split(':').reverse()
      dservice.cluster ?= dcluster or cluster.id
      dservice.service = did or null
      # Module
      throw Error 'Unidentified Dependency: require module or service property' unless dservice.service or dservice.module
      # Attempt to set service name by matching module name
      unless dservice.service
        sids = for searchname, searchservice of config.clusters[dservice.cluster].services
          modulename = searchservice.module or searchname
          continue unless modulename is dservice.module
          searchservice.id or searchname
        throw Error "Invalid Service Reference: multiple matches for module #{JSON.stringify dservice.module} in cluster #{JSON.stringify dservice.cluster}" if sids.length > 1
        dservice.service = sids[0] if sids.length is 1
      # Auto
      if dservice.auto and not dservice.disabled and not config.clusters[dservice.cluster].services[dservice.service]
        throw Error 'Not sure if dservice.service can even exist here' if dservice.service
        dservice.service = dservice.module
        dservice =
          id: dservice.service
          cluster: dservice.cluster
          module: dservice.module
        config.clusters[dservice.cluster].services[dservice.id] = dservice
        discover_service dservice.cluster, dservice.id, dservice
  # Initial cluster and service normalization
  for cname, cluster of config.clusters
    cluster = config.clusters[cname] = {} if cluster is true
    cluster.id = cname
    throw Error "Invalid Cluster: expect an object, got #{JSON.stringify cluster}" unless is_object cluster
    cluster.services ?= {}
    # Load module and extends current service definition
    for sname, service of cluster.services
      discover_service cname, sname, service
  # Normalize service
  for cname, cluster of config.clusters
    for sname, service of cluster.services
      service.id = sname
      service.cluster = cname
      service.affinity ?= []
      service.affinity = [service.affinity] if is_object service.affinity
      for affinity in service.affinity
        affinity.type ?= 'generic'
        try
          throw Error "Unsupported Affinity Type: got #{affinity.type}, accepted values are #{JSON.stringify Object.keys affinities.handlers}" unless affinities.handlers[affinity.type]
          affinities.handlers[affinity.type].normalize affinity
        catch err
          err.message += " in service #{JSON.stringify sname} of cluter #{JSON.stringify cname}"
          throw err
      # Normalize commands
      service.commands ?= {}
      for cmdname, command of service.commands
        command = service.commands[cmdname] = [command] unless Array.isArray command
        for mod in command
          throw Error "Invalid Command: accept array, string or function, got #{JSON.stringify mod} for command #{JSON.stringify cmdname}" unless typeof mod in ['string', 'function']
      # Default empty node list
      service.nodes ?= []
  # Dependencies
  for cname, cluster of config.clusters
    for sname, service of cluster.services
      for dname, dservice of service.deps
        # If cluster isnt found, throw an error if required or disable the dependency
        unless config.clusters[dservice.cluster]
          if dservice.required
            throw Error "Invalid Cluster Reference: cluster #{JSON.stringify dservice.cluster} is not defined"
          else
            dservice.disabled = true
            continue
        if config.clusters[dservice.cluster].services[dservice.service]
          dservice.disabled ?= false
        else
          if dservice.required
            if dservice.service
              throw Error "Required Dependency: unsatisfied dependency #{JSON.stringify dname} in service #{JSON.stringify [service.cluster, service.id].join ':'}, service #{JSON.stringify dservice.service} in cluster #{JSON.stringify dservice.cluster} is not defined"
            else
              throw Error "Required Dependency: unsatisfied dependency #{JSON.stringify dname} in service #{JSON.stringify [service.cluster, service.id].join ':'}, module #{JSON.stringify dservice.module} in cluster #{JSON.stringify dservice.cluster} is not defined"
          else
            dservice.disabled ?= true
  # Normalize nodes
  for nname, node of config.nodes
    node = config.nodes[nname] = {} if node is true
    node.id ?= nname
    node.fqdn ?= nname
    node.hostname ?= nname.split('.').shift()
    node.services ?= []
    # Validate service registration
    for service in node.services
      if service.service
        unless config.clusters[service.cluster].services[service.service]
          throw Error "Node Invalid Service: node #{JSON.stringify node.id} references missing service #{JSON.stringify service.service} in cluster #{JSON.stringify service.cluster}"
  # Graph ordering
  graph = tsort()
  for cname, cluster of config.clusters
    for sname, service of cluster.services
      graph.add "#{cname}:#{sname}"
      for _, dservice of service.deps
        continue if dservice.service is sname
        continue if dservice.disabled
        graph.add "#{dservice.cluster}:#{dservice.service}", "#{cname}:#{sname}"
  services = graph.sort()
  config.graph = services
  # Affinity discovery
  for service in services.slice().reverse()
    [cname, sname] = service.split ':'
    service = config.clusters[cname].services[sname]
    if service.affinity.length
      affinity = (
        if service.affinity.length > 1
          type: 'generic'
          match: 'any'
          values: service.affinity or []
        else
          service.affinity[0]
      )
      service.nodes = affinities.handlers[affinity.type].resolve config, affinity
    # Enrich service list in nodes
    for node in service.nodes
      found = null
      for srv, i in config.nodes[node].services
        if srv.cluster is cname and srv.service is sname
          found = i
          break
      if found?
        config.nodes[node].services[i].module ?= service.module
      else
        config.nodes[node].services.push cluster: cname, service: sname, module: service.module
    # Enrich affinity for dependencies marked as auto
    for dname, dep of service.deps
      continue unless dep.auto
      continue if dep.disabled
      sdep = config.clusters[dep.cluster].services[dep.service]
      values = {}
      for node in service.nodes
        values[node] = true
      sdep.affinity.push type: 'nodes', match: 'any', values: values
  # Re-order node services
  for nname, node of config.nodes
    node.services.sort (a, b)->
      services.indexOf("#{a.cluster}:#{a.service}") - services.indexOf("#{b.cluster}:#{b.service}")
  # Re-validate required dependency ensuring affinity is compatible with local
  for cname, cluster of config.clusters
    for sname, service of cluster.services
      for dname, dep of service.deps
        continue unless dep.local and dep.required
        for snode in service.nodes
          dservice = config.clusters[dep.cluster].services[dep.service]
          continue if snode in dservice.nodes
          throw Error "Required Local Dependency: service #{JSON.stringify sname} in cluster #{JSON.stringify cname} require service #{JSON.stringify dep.service} in cluster #{JSON.stringify dep.cluster} to be present on node #{snode}"

  # Enrich configuration
  for service in services
    [cname, sname] = service.split ':'
    service = config.clusters[cname].services[sname]
    # Load configuration
    service.service_by_nodes ?= {}
    for node in service.nodes
      node = config.nodes[node]
      # Copy options
      options = merge {}, service.options
      # Overwrite options from node
      node_services = node.services.filter (srv) -> srv.cluster is service.cluster and srv.service is service.id
      if node_services.length is 1
        options = merge {}, options, node_services[0].options
      else if node_services.length > 1
        throw Error 'Should never happen'
      service.service_by_nodes[node.id] =
        service: service.id
        cluster: service.cluster
        options: options
        node: node
        nodes: Object.values(config.nodes).filter (node) -> node.id in service.nodes
    # Load deps and run configure
    for node in service.nodes
      node = config.nodes[node]
      deps = {}
      for dname, dep of service.deps
        # Handle not satisfied dependency
        continue if dep.disabled
        # Get dependency service
        deps[dname] = Object.values config.clusters[dep.cluster].services[dep.service].service_by_nodes
        if dep.single
          throw Error "Invalid Option: single only appy to 0 or 1 dependencies, found #{deps[dname].length}" if deps[dname].length isnt 1
          deps[dname] = deps[dname][0] or null
        if dep.local
          deps[dname] = [deps[dname]] if dep.single
          deps[dname] = deps[dname].filter (dep) ->
            dep.node.id is node.id
          deps[dname] = deps[dname][0] or null
      # service.service_by_nodes[node.id].deps = deps
      inject =
        service: service.service_by_nodes[node.id].id
        cluster: service.service_by_nodes[node.id].cluster
        options: service.service_by_nodes[node.id].options
        node: service.service_by_nodes[node.id].node
        nodes: service.service_by_nodes[node.id].nodes
        deps: deps
      if service.configure
        try
          service.configure = load service.configure if typeof service.configure is 'string'
        catch err
          err.message += " in service #{JSON.stringify service.id} of cluter #{JSON.stringify service.cluster}"
          throw err
        throw Error "Invalid Configuration: not a function, got #{typeof service.configure}" unless typeof service.configure is 'function'
        service.configure.call null, inject
      newinject = {}
      for k, v of service.service_by_nodes[node.id]
        continue if k is 'deps'
        # continue if k is 'nodes'
        newinject[k] = v
      service.service_by_nodes[node.id] = newinject
      # delete service.service_by_nodes[node.id].deps
  config

is_object = (obj) ->
  obj and typeof obj is 'object' and not Array.isArray obj
