
import params from 'masson/params'
import path from 'path'
import util from 'node:util'
import CSON from 'cson'
import string from '@nikitajs/core/utils/string'
import load from 'masson/config/load'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

# ./bin/ryba configure -o output_file -p JSON
export default ({params}, config) ->
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
