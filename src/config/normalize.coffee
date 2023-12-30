
import tsort from 'tsort'
import {merge, mutate} from 'mixme'
import load from 'masson/utils/load'
import affinities from 'masson/config/affinities'

export default (config) ->
  if config.clusters? and not is_object config.clusters
    return Promise.reject Error "Invalid Clusters: expect an object, got #{JSON.stringify config.clusters}"
  if config.services? and not is_object config.services
    return Promise.reject Error "Invalid Services: expect an object, got #{JSON.stringify config.services}"
  if config.nodes? and not is_object config.nodes
    return Promise.reject Error "Invalid Nodes: expect an object, got #{JSON.stringify config.nodes}"
  config.params ?= {}
  config.clusters ?= {}
  config.nodes ?= {}
  discover_service = (cname, sname, service)->
    service = config.clusters[cname].services[sname] = {} if service is true
    service.module ?= sname
    # Load service module
    externalModDef = await load service.module
    return Promise.reject Error "Invalid Service Definition: expect an object for module #{JSON.stringify service.module}, got #{JSON.stringify typeof externalModDef}" unless is_object externalModDef
    mutate service, externalModDef
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
      return Promise.reject Error 'Unidentified Dependency: require module or service property' unless dservice.service or dservice.module
      # Attempt to set service name by matching module name
      unless dservice.service
        sids = for searchname, searchservice of config.clusters[dservice.cluster].services
          modulename = searchservice.module or searchname
          continue unless modulename is dservice.module
          searchservice.id or searchname
        return Promise.reject Error "Invalid Service Reference: multiple matches for module #{JSON.stringify dservice.module} in cluster #{JSON.stringify dservice.cluster}" if sids.length > 1
        dservice.service = sids[0] if sids.length is 1
      # Auto
      if dservice.auto and not dservice.disabled and not config.clusters[dservice.cluster].services[dservice.service]
        return Promise.reject Error 'Not sure if dservice.service can even exist here' if dservice.service
        dservice.service = dservice.module
        dservice =
          id: dservice.service
          cluster: dservice.cluster
          module: dservice.module
        config.clusters[dservice.cluster].services[dservice.id] = dservice
        await discover_service dservice.cluster, dservice.id, dservice
  # Initial cluster and service normalization
  for cname, cluster of config.clusters
    cluster = config.clusters[cname] = {} if cluster is true
    cluster.id = cname
    return Promise.reject Error "Invalid Cluster: expect an object, got #{JSON.stringify cluster}" unless is_object cluster
    cluster.services ?= {}
    # Load module and extends current service definition
    for sname, service of cluster.services
      await discover_service cname, sname, service
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
          return Promise.reject Error "Unsupported Affinity Type: got #{affinity.type}, accepted values are #{JSON.stringify Object.keys affinities.handlers}" unless affinities.handlers[affinity.type]
          affinities.handlers[affinity.type].normalize affinity
        catch err
          err.message += " in service #{JSON.stringify sname} of cluster #{JSON.stringify cname}"
          return Promise.reject err
      # Normalize commands
      service.commands ?= {}
      for cmdname, command of service.commands
        command = service.commands[cmdname] = [command] unless Array.isArray command
        for mod in command
          return Promise.reject Error "Invalid Command: accept array, string or function, got #{JSON.stringify mod} for command #{JSON.stringify cmdname}" unless typeof mod in ['string', 'function'] or is_object mod
      # Default empty node list
      service.nodes ?= {}
      service.instances = []
      # for snodeid, snode of service.nodes
      #   return Promise.reject Error "Invalid Node Id" if snode.id and snode.id isnt snodeid
      #   snode.id = snodeid
  # Dependencies
  for cname, cluster of config.clusters
    for sname, service of cluster.services
      for dname, dservice of service.deps
        # If cluster isnt found, throw an error if required or disable the dependency
        unless config.clusters[dservice.cluster]
          if dservice.required
            return Promise.reject Error "Invalid Cluster Reference: cluster #{JSON.stringify dservice.cluster} is not defined"
          else
            dservice.disabled = true
            continue
        if config.clusters[dservice.cluster].services[dservice.service]
          dservice.disabled ?= false
        else
          if dservice.required
            if dservice.service
              return Promise.reject(Error "Required Dependency: unsatisfied dependency #{JSON.stringify dname} in service #{JSON.stringify [service.cluster, service.id].join ':'}, service #{JSON.stringify dservice.service} in cluster #{JSON.stringify dservice.cluster} is not defined")
            else
              return Promise.reject(Error "Required Dependency: unsatisfied dependency #{JSON.stringify dname} in service #{JSON.stringify [service.cluster, service.id].join ':'}, module #{JSON.stringify dservice.module} in cluster #{JSON.stringify dservice.cluster} is not defined")
          else
            dservice.disabled ?= true
  # Normalize nodes
  for nname, node of config.nodes
    node = config.nodes[nname] = {} if node is true
    node.id ?= nname
    node.fqdn ?= nname
    node.hostname ?= nname.split('.').shift()
    node.services ?= []
    # Convert services to an array
    if is_object node.services
      node.services = for sid, service of node.services
        [cname, sname] = sid.split ':'
        cluster: cname
        service: sname
        options: service
    # Validate service registration
    for service in node.services
      if service.service
        unless config.clusters[service.cluster].services[service.service]
          return Promise.reject Error "Node Invalid Service: node #{JSON.stringify node.id} references missing service #{JSON.stringify service.service} in cluster #{JSON.stringify service.cluster}"
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
      nodeids = affinities.handlers[affinity.type].resolve config, affinity
      for instance in service.instances
        return Promise.reject Error "No Affinity Found: #{instance.node.id}" if instance.node.id not in nodeids
      for nodeId in nodeids
        service.instances.push
          id: nodeId
          cluster: service.cluster
          service: service.id
          node: merge config.nodes[nodeId]
          options: service.nodes[nodeId] or {}
        # service.nodes[nodeId] ?= {}
        # service.nodes[nodeId].id = nodeId
        # service.nodes[nodeId].cluster = service.cluster
        # service.nodes[nodeId].service = service.id
        # service.nodes[nodeId].node = merge config.nodes[nodeId]
        # service.nodes[nodeId].options ?= {}
    # Enrich service list in nodes
    for instance in service.instances
      found = null
      for srv, i in config.nodes[instance.node.id].services
        if srv.cluster is cname and srv.service is sname
          found = i
          break
      if found?
        config.nodes[instance.node.id].services[found].module ?= service.module
        instance.node.services.push merge config.nodes[instance.node.id].services[found]
      else
        config.nodes[instance.node.id].services.push cluster: cname, service: sname, module: service.module
        instance.node.services.push cluster: cname, service: sname, module: service.module
    # Enrich affinity for dependencies marked as auto
    for dname, dep of service.deps
      continue unless dep.auto
      continue if dep.disabled
      sdep = config.clusters[dep.cluster].services[dep.service]
      values = {}
      for instance in service.instances
        values[instance.node.id] = true
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
        dservice = config.clusters[dep.cluster].services[dep.service]
        for instance in service.instances
          continue if instance.node.id in dservice.instances.map (instance) -> instance.node.id
          return Promise.reject Error "Required Local Dependency: service #{JSON.stringify sname} in cluster #{JSON.stringify cname} require service #{JSON.stringify dep.service} in cluster #{JSON.stringify dep.cluster} to be present on node #{instance.node.id}"
  # Enrich configuration
  for service in services
    [cname, sname] = service.split ':'
    service = config.clusters[cname].services[sname]
    # Load configuration
    for instance in service.instances
      node = config.nodes[instance.node.id]
      # Get options from node
      node_services = node.services.filter (srv) -> srv.cluster is service.cluster and srv.service is service.id
      return Promise.reject Error 'Should never happen' if node_services.length > 1
      noptions = if node_services.length is 1 then node_services[0].options else {}
      # Overwrite options from service.nodes
      # if service.nodes[node.id]
      #   options = merge options, service.nodes[node.id].options
      instance.options = merge service.options, noptions, service.nodes[instance.node.id]
    # Load deps and run configure
    for instance in service.instances
      node = config.nodes[instance.node.id]
      deps = {}
      for dname, dep of service.deps
        # Handle not satisfied dependency
        continue if dep.disabled
        # Get dependency service
        deps[dname] = config.clusters[dep.cluster].services[dep.service].instances
        if dep.single
          return Promise.reject Error "Invalid Option: single only apply to 1 dependencies, found #{deps[dname].length}" if deps[dname].length isnt 1
          deps[dname] = deps[dname][0] or null
        if dep.local
          deps[dname] = [deps[dname]] if dep.single
          deps[dname] = deps[dname].filter (dep) ->
            dep.id is node.id
          deps[dname] = deps[dname][0] or null
      inject =
        cluster: instance.cluster
        service: instance.service
        options: instance.options
        instances: service.instances
        node: merge node
        deps: deps
      if service.configure
        try
          service.configure = await load service.configure if typeof service.configure is 'string'
        catch err
          err.message += " in service #{JSON.stringify service.id} of cluster #{JSON.stringify service.cluster}"
          return Promise.reject err
        return Promise.reject Error "Invalid Configuration: not a function, got #{typeof service.configure}" unless typeof service.configure is 'function'
        service.configure.call null, inject
      # newinject = {}
      # for instance in service.instances
      #   continue unless instance.node.id is instance.
      # for k, v of service.nodes[instance.node.id]
      #   continue if k is 'deps'
      #   newinject[k] = v
      # service.instances[instance.node.id] = newinject
  config

is_object = (obj) ->
  obj and typeof obj is 'object' and not Array.isArray obj
