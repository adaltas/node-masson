
import path from 'path'
import nikita from 'nikita'
import each from 'each'
import store from 'masson/config/store'
import flatten from 'masson/utils/flatten'
import multimatch from 'masson/utils/multimatch'
import {merge} from 'mixme'
import array_get from 'masson/utils/array_get'

export default ({params}, config) ->
  command = params.command.slice(-1)[0]
  for tag in params.tags or {}
    [key, value] = tag.split '='
    throw Error "Invalid usage, expected --tags key=value" if not value
  s = store(config)
  each s.nodes(), true, (node) ->
    for tag in params.tags or {}
      [key, value] = tag.split '='
      return if multimatch(node.tags[key] or [], value.split(',')).length is 0
    return if params.nodes and multimatch([node.ip, node.fqdn, node.hostname], params.nodes).length is 0
    # Get filtered services
    services = node.services
    # Filtering based on module name
    .filter (service) ->
      (not params.modules or multimatch(service.module, params.modules).length) and
      (not params.cluster or multimatch(service.cluster, params.cluster).length)
    # Keep only service with a matching command
    .filter (service) ->
      s.service service.cluster, service.service
      .commands[command]
    return unless services.length
    log = {}
    log.basedir ?= './log'
    log.basedir = path.resolve process.cwd(), log.basedir
    config.nikita.no_ssh = true
    n = nikita merge config.nikita
    await n.log.cli host: node.fqdn, pad: host: 20, header: 60
    await n.log.md basename: node.hostname, basedir: log.basedir, archive: false
    await n.ssh.open
      $header: 'SSH Open'
      host: node.ip or node.fqdn
    , node.ssh
    # Call the plugin of every service, discard filtering
    n.call ->
      for service in node.services
        service = s.service(service.cluster, service.service)
        continue unless service.plugin
        instance = array_get(service.instances, (instance) -> instance.node.id is node.id)
        n.call service.plugin, merge instance.options
    # Call the command of the filtered services
    n.call ->
      for service in services
        service = s.service service.cluster, service.service
        # Retrieve the service instance associated with this node
        instance = array_get service.instances, (instance) -> instance.node.id is node.id
        # Call each registered module
        for module in service.commands[command]
          isRoot = config.nikita.ssh.username is 'root' or not config.nikita.ssh.username
          n.call module, merge instance.options, sudo: not isRoot
  .catch (err) ->
    unless err.errors
      process.stderr.write "\n#{err.stack}\n"
    else for err in err.errors
      process.stderr.write "\n#{err.stack}\n"
    # throw err
    
