
path = require 'path'
nikita = require 'nikita'
each = require 'each'
store = require '../config/store'
flatten = require '../utils/flatten'
multimatch = require '../utils/multimatch'
mixme = require 'mixme'
array_get = require '../utils/array_get'

module.exports = (params, config, callback) ->
  s = store(config)
  engine = require('@nikitajs/core/lib/core/kv/engines/memory')()
  each s.nodes()
  .parallel(true)
  .call (node, callback) ->
    for tag in params.tags or {}
      [key, value] = tag.split '='
      throw Error "Invalid usage, expected --tags key=value" if not value
      return callback() if multimatch(node.tags[key] or [], value.split(',')).length is 0
    return callback() if params.nodes and multimatch([node.ip, node.fqdn, node.hostname], params.nodes).length is 0
    log = {}
    log.basedir ?= './log'
    log.basedir = path.resolve process.cwd(), log.basedir
    config.nikita.no_ssh = true
    n = nikita mixme {}, config.nikita
    n.kv.engine engine: engine
    n.log.cli host: node.fqdn, pad: host: 20, header: 60
    n.log.md basename: node.hostname, basedir: log.basedir, archive: false
    n.next (->) #swallow Invalid Directory on log directory
    n.ssh.open
      header: 'SSH Open'
      host: node.ip or node.fqdn
    , node.ssh
    n.call ->
      for service in node.services
        service = s.service(service.cluster, service.service)
        continue unless service.plugin
        instance = array_get(service.instances, (instance) -> instance.node.id is node.id)
        n.call service.plugin, mixme {}, instance.options
    n.call -> # config.actions, 
      for service in node.services
        service = s.service service.cluster, service.service
        continue if params.modules and multimatch(service.module, params.modules).length is 0
        instance = array_get service.instances, (instance) -> instance.node.id is node.id
        if service.commands[params.command]
          for module in service.commands[params.command]
            isRoot = config.nikita.ssh.username is 'root' or not config.nikita.ssh.username
            n.call module, mixme {}, instance.options, sudo: not isRoot
    n.next (err) ->
      n.ssh.close header: 'SSH Close' #unless params.command is 'prepare' # params.end and
      # process.stdout.write err.message + '\n' if err
      n.next -> callback err
  .next (err) ->
    if err
      unless err.errors
        process.stderr.write "\n#{err.stack}\n"
      else for err in err.errors
        process.stderr.write "\n#{err.stack}\n"
    else
      process.stdout.write 'Finish with success'
    callback err
    
