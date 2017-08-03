
###
migration(service, module, module_key, uses)

###

module.exports = (service, srv, keys, uses) ->
  nikita_options = {}
  for k, v of @options
    continue if k is 'ssh'
    nikita_options[k] = v
  use = {}
  for use_srv_key, use_srv of uses
    srv_ctxs = @contexts use_srv.module
    if use_srv.local
      srv_ctxs.filter (ctx) => ctx.config.host is @config.host
    srv_ctxs = srv_ctxs.map (ctx) =>
      options = null
      throw Error 'No key' unless use_srv.key
      for key in use_srv.key
        unless options
          unless ctx.config[key]
            options = null
            break
          options = merge {}, ctx.config[key]
        else
          unless options[key]
            options = null
            break
          options = options[key]
      node: 
        ip: ctx.config.ip
        hostname: ctx.config.shortname
        fqdn: ctx.config.host
      options: merge {}, nikita_options, options
    # console.log '>>', srv_ctxs
    if use_srv.local
      srv_ctxs = srv_ctxs[0]
    use[use_srv_key] = srv_ctxs
  options = null
  for key in keys
    unless options
      unless @config[key]
        options = null
        continue
      options = merge {}, @config[key]
    else
      unless options[key]
        options = null
        continue
      options = options[key]
  options = merge {}, nikita_options, options
  use: use
    # ssl: @contexts('masson/core/ssl').filter( (ctx) => ctx.config.host is @config.host ).map (ctx) -> options: ctx.config.ssh
    # mariadb: @contexts('masson/commons/mariadb/server').map (ctx) -> options: ctx.config.mariadb.server
  node:
    # id: @config.node
    ip: @config.ip
    hostname: @config.shortname
    fqdn: @config.host
  nodes: @contexts(srv).map (ctx) -> 
    # id: ctx.config.node
    ip: ctx.config.ip
    hostname: ctx.config.shortname
    fqdn: ctx.config.host
  options: options

{merge} = require 'nikita/lib/misc'
