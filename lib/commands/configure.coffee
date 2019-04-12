
params = require '../params'
path = require 'path'
util = require 'util'
CSON = require 'cson'
string = require '@nikitajs/core/lib/misc/string'
load = require '../config/load'
normalize = require '../config/normalize'
store = require '../config/store'

# ./bin/ryba configure -o output_file -p JSON
module.exports = ({params}, config) ->
  # EXAMPLE START
  params.output ?= 'export'
  # params.format ?= 'coffee'
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
    print s.nodes()
  else if params.node
    print s.node params.node
  else if params.service
    throw Error "Required Option: #{params.cluster}" unless params.cluster
    print s.service params.cluster, params.service
  else if params.cluster
    print s.cluster params.cluster
  else if params.cluster_names
    print s.cluster_names()
  else if params.service_names
    print s.service_names()
  else
    print config
