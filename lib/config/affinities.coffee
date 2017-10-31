
flatten = require '../utils/flatten'

module.exports =
  nodes: (config, cluster, service) ->
    nodes = {}
    for _, cluster of config.cluster
      for _, service of cluster.services
        for _, node of service.nodes
          nodes[node] ?= true
    Object.keys nodes
    
  services: (config, node) ->
    services = {}
    for _, node of config.nodes
      for _, service of node.services
        services[service] = true
    Object.keys services

  handlers:
    generic:
      normalize: (config) ->
        config.type ?= 'generic'
        throw Error "Required Property: \"values\" not found" unless config.values
        throw Error "Invalid Property: \"values\" not an array" unless Array.isArray config.values
        for value in config.values
          throw Error "Required Property: \"type\"" unless value.type
          # throw Error "Required Property: match" unless value.match
          throw Error "Unsupported Affinity Type: got #{JSON.stringify value.type}, accepted values are #{JSON.stringify Object.keys module.exports.handlers}" unless module.exports.handlers[value.type]
          module.exports.handlers[value.type].normalize value
        config
      resolve: (config, affinity) ->
        nodeids = Object.values(config.nodes).map( (node) -> node.id)
        matchednodes = []
        for value in affinity.values
          matchednodes.push module.exports.handlers[value.type].resolve config, value
        # matchednodes = flatten matchednodes
        match[affinity.match or 'all'] matchednodes, nodeids, nodeids
    tags:
      normalize: (config) ->
        throw Error "Required Property: \"values\" not found" unless config.values
        throw Error "Invalid Property: \"values\", expect an object" unless is_object config.values
        for tag, tconfig of config.values
          tconfig = config.values[tag] = values: [tconfig] if typeof tconfig is 'string'
          tconfig = config.values[tag] = values: tconfig if Array.isArray tconfig
          if Array.isArray tconfig.values
            values = tconfig.values
            tconfig.values = {}
            for value in values
              throw Error "Invalid Property: \"values\", expect a string" unless typeof value is 'string'
              tconfig.values[value] = true
          # Validation
          throw Error "Required Property: \"match\", when more than one value" if Object.keys(tconfig.values).length > 1 and not tconfig.match
          for value in tconfig.values
            throw Error "Invalid Property: \"value\", must be true"
        # Validation        
        throw Error "Required Property: \"match\", when more than one tag" if Object.keys(config.values).length > 1 and not config.match
        config
      resolve: (config, affinity) ->
        nodeids = Object.values(config.nodes).map( (node) -> node.id)
        # fqdns = Object.values(config.nodes).map( (node) -> node.fqdn)
        matchednodes = []
        for name, tag of affinity.values
          nodetags = 
          values = Object.keys(tag.values)
          subjects = Object.values(config.nodes).map( (node) -> node.tags?[name])
          # Get the matching nodes for this tag
          matchednodes.push match[tag.match or 'all'] values, subjects, nodeids
        match[affinity.match or 'all'] matchednodes, nodeids, nodeids
    services:
      normalize: (config) ->
        throw Error "Required Property: \"values\" not found" unless config.values
        config.values = [config.values] if typeof config.values is 'string'
        if Array.isArray config.values
          services = config.values
          config.values = {}
          for service in services
            throw Error "Invalid Property: \"service\" expect a string" unless typeof service is 'string'
            config.values[service] = true
        config
      resolve: (config, affinity) ->
        console.log 'todo'
    nodes:
      normalize: (config) ->
        throw Error "Required Property: \"values\" not found" unless config.values
        config.values = [config.values] if typeof config.values is 'string'
        if Array.isArray config.values
          nodes = config.values
          config.values = {}
          for node in nodes
            throw Error "Invalid Property: \"node\", expect a string" unless typeof node is 'string'
            config.values[node] = true
        throw Error "Required Property: \"match\", when more than one values" if Object.keys(config.values).length > 1 and not config.match
        config
      resolve: (config, affinity) ->
        fqdns = Object.values(config.nodes).map( (node) -> node.fqdn)
        match[affinity.match or 'all'] Object.keys(affinity.values), fqdns, fqdns

match =
  # Return any subject which match all the left values
  all: (values, subjects, result) ->
    result.filter (value, i) ->
      subject = subjects[i]
      subject = [subject] if typeof subject is 'string'
      ok = true
      for value in values
        value = [value] if typeof value is 'string'
        ok = false unless any value, subject
        # ok = false unless value in subject
      ok
  # Return any subject which match at least one left values
  any: (values, subjects, result) ->
    result.filter (value, i) ->
      subject = subjects[i]
      subject = [subject] if typeof subject is 'string'
      for value in values
        value = [value] if typeof value is 'string'
        return true if any value, subject
      false
  # Return any subject which match no left values
  none: (values, subjects, result) ->
    result.filter (value, i) ->
      subject = subjects[i]
      subject = [subject] if typeof subject is 'string'
      for value in values
        value = [value] if typeof value is 'string'
        return false if any value, subject
      true

any = (a, b) ->
  for aa in a
    return true if aa in b
  false

is_object = (obj) ->
  obj and typeof obj is 'object' and not Array.isArray obj
          
      
        
