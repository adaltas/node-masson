
path = require 'path'
nikita = require 'nikita'
each = require 'each'
store = require '../config/store'
flatten = require '../utils/flatten'
multimatch = require '../utils/multimatch'
merge = require '../utils/merge'
array_get = require '../utils/array_get'

module.exports = (params, config, callback) ->
  s = store(config)
  engine = require('nikita/lib/core/kv/engines/memory')()
  each s.nodes()
  .parallel(true)
  .call (node, callback) ->
    return callback() if params.nodes and multimatch([node.ip, node.fqdn, node.hostname], params.nodes).length is 0
    log = {}
    log.basedir ?= './log'
    log.basedir = path.resolve process.cwd(), log.basedir
    config.nikita.no_ssh = true
    n = nikita merge {}, config.nikita
    n.kv.engine engine: engine
    n.log.cli host: node.fqdn, pad: host: 20, header: 60
    n.log.md basename: node.hostname, basedir: log.basedir, archive: false
    n.ssh.open header: 'SSH Open', host: node.ip or node.fqdn #unless params.command is 'prepare'
    n.call ->
      for service in node.services
        service = s.service(service.cluster, service.service)
        continue unless service.plugin
        # n.call service.plugin, merge {}, service.nodes[node.id].options
        instance = array_get(service.instances, (instance) -> instance.node.id is node.id)
        n.call service.plugin, merge {}, instance.options
    n.call ->
      for service in node.services
        service = s.service(service.cluster, service.service)
        # masson 1 has `!service.required and ` in following condition
        continue if params.modules and multimatch(service.module, params.modules).length is 0
        console.log "found empty command in #{service.module}" if service.commands['']
        instance = array_get(service.instances, (instance) -> instance.node.id is node.id)
        if service.commands[params.command]
          for module in service.commands[params.command]
            n.call module, merge {}, instance.options
    n.then (err) ->
      n.ssh.close header: 'SSH Close' #unless params.command is 'prepare' # params.end and 
      n.then ->
        console.log err if err
        return
        callback err
  .next (err) ->
    message = if err
    then 'Finish with err: ' + err.message
    else 'Finish with success'
    process.stdout.write '\n' + message + '\n\n'
    callback err
    
