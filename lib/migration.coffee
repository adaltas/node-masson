
###
migration(service, module, module_key, uses)

Possible dependency attributes:
* local (boolean)   
  use point to the local service definition instead of an array
* single (boolean)
  use enforce and return only one service definition

###

module.exports = (service, srv, keys, uses) ->
  nikita_options = {}
  for k, v of @options
    continue if k is 'ssh'
    nikita_options[k] = v
  use = {}
  for use_srv_key, use_srv of uses
    try
      srv_ctxs = @contexts use_srv.module
    catch e
      throw Error "Failed to get context: #{use_srv_key} in #{use_srv.module}", e
    if use_srv.local
      srv_ctxs = srv_ctxs.filter (ctx) => ctx.config.host is @config.host
    if use_srv.single
      throw Error "Service #{use_srv_key} is marked as unique" if srv_ctxs.length > 1
    if use_srv.required
      throw Error "Service #{use_srv_key} is marked as required" unless srv_ctxs.length
    srv_ctxs = srv_ctxs.map (ctx) =>
      options = null
      throw Error "No key for sevice: #{use_srv_key}" unless use_srv.key
      for key in use_srv.key
        unless options
          unless ctx.config[key]
            options = null
            break
          options = ctx.config[key]
        else
          unless options[key]
            options = null
            break
          options = options[key]
      node: 
        ip: ctx.config.ip
        hostname: ctx.config.shortname
        fqdn: ctx.config.host
      options: merge options, nikita_options, options
    if use_srv.local
      srv_ctxs = srv_ctxs[0]
    if use_srv.single
      srv_ctxs = srv_ctxs[0]
    # if use_srv.required
    #   if use_srv.local or use_srv.single
    #     throw Error "Service #{use_srv_key} is marked as required" unless srv_ctxs
    #   else
    #     throw Error "Service #{use_srv_key} is marked as required" unless srv_ctxs.length
    # Note, in real future world, we will accept empty array if a service is define but not defined anywhere
    srv_ctxs = null if srv_ctxs?.length is 0
    use[use_srv_key] = srv_ctxs
  options = null
  for key in keys
    unless options
      unless @config[key]
        options = null
        continue
      options = @config[key]
    else
      unless options[key]
        options = null
        continue
      options = options[key]
  options = merge options, nikita_options, options
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
