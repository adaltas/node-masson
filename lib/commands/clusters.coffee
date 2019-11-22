
path = require 'path'
nikita = require 'nikita'
each = require 'each'
store = require '../config/store'
flatten = require '../utils/flatten'
multimatch = require '../utils/multimatch'
{merge} = require 'mixme'
array_get = require '../utils/array_get'

module.exports = ({params}, config, callback) ->
  command = params.command.slice(-1)[0]
  for tag in params.tags or {}
    [key, value] = tag.split '='
    return callback Error "Invalid usage, expected --tags key=value" if not value
  s = store(config)
  engine = require('@nikitajs/core/lib/core/kv/engines/memory')()
  each s.nodes()
  .parallel(true)
  .call (node, callback) ->
    for tag in params.tags or {}
      [key, value] = tag.split '='
      return callback() if multimatch(node.tags[key] or [], value.split(',')).length is 0
    return callback() if params.nodes and multimatch([node.ip, node.fqdn, node.hostname], params.nodes).length is 0
    services = node.services
    # Filtering based on module name
    .filter (service) ->
      (not params.modules or multimatch(service.module, params.modules).length) and
      (not params.cluster or multimatch(service.cluster, params.cluster).length)
    # Keep only service with a matching command
    .filter (service) ->
      s.service service.cluster, service.service
      .commands[command]
    return callback() unless services.length
    log = {}
    log.basedir ?= './log'
    log.basedir = path.resolve process.cwd(), log.basedir
    config.nikita.no_ssh = true
    n = nikita merge config.nikita
    n.kv.engine engine: engine
    n.log.cli host: node.fqdn, pad: host: 20, header: 60
    n.log.md basename: node.hostname, basedir: log.basedir, archive: false
    # Swallow "Invalid Directory" error on log directory
    n.next ((err) ->)
    n.ssh.open
      header: 'SSH Open'
      host: node.ip or node.fqdn
    , node.ssh
    n.call ->
      for service in node.services
        service = s.service(service.cluster, service.service)
        continue unless service.plugin
        instance = array_get(service.instances, (instance) -> instance.node.id is node.id)
        n.call service.plugin, merge instance.options
    n.call ->
      for service in services
        service = s.service service.cluster, service.service
        # Retrieve the service instance associated with this node
        instance = array_get service.instances, (instance) -> instance.node.id is node.id
        # Call each registered module
        for module in service.commands[command]
          isRoot = config.nikita.ssh.username is 'root' or not config.nikita.ssh.username
          n.call module, merge instance.options, sudo: not isRoot
    n.next (err) ->
      n.ssh.close header: 'SSH Close'
      n.next -> callback err
  .next (err) ->
    if err
      unless err.errors
        process.stderr.write "\n#{err.stack}\n"
      else for err in err.errors
        process.stderr.write "\n#{err.stack}\n"
    callback err
    
