
params = require '../params'
path = require 'path'
util = require 'util'
CSON = require 'cson'
string = require 'nikita/lib/misc/string'
load = require '../config/load'
normalize = require '../config/normalize'
store = require '../config/store'

# ./bin/ryba graph -o output_file -p JSON
module.exports = (params, config) ->
  params.output ?= 'export'
  params.output = path.resolve process.cwd(), params.output
  params.hosts = [params.hosts] if typeof params.hosts is 'string'
  # Print host cfg on path
  print = (config) ->
    config = switch params.format
      when 'cson'
        CSON.stringify(config, null, 2)
      when 'json'
        JSON.stringify(config, null, 2)
      when 'js'
        "module.exports = #{JSON.stringify config, null, 2}"
      when 'coffee'
        # adds 2 spaces to the stringified object for CSON indentation before writing it
        content = (string.lines CSON.stringify(config, null, 2)).join("\n  ")
        "module.exports =\n  #{content}"
      else
        util.inspect config, depth: null, colors: true
    process.stdout.write config
  s = store config
  if params.nodes
    if params.format
      output = for service in config.graph
        [cname, sname] = service.split ':'
        service = config.clusters[cname].services[sname]
        cluster: service.cluster
        id: service.id
        module: service.module
        nodes: service.nodes
      print output
    else
      for service, i in config.graph
        [cname, sname] = service.split ':'
        service = config.clusters[cname].services[sname]
        process.stdout.write [
          "* #{service.cluster}:#{service.id}"
          " (#{service.module})" unless service.id is service.module
          '\n'
        ].join ''
        for node in service.nodes
          process.stdout.write "  * #{node}\n"
        process.stdout.write '\n'
  else
    print config.graph
