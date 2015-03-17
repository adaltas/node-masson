  
path = require 'path'
fs = require 'fs'
{merge} = require './misc'
# params = require './params'
# params = params.parse()

module.exports = (paths, callback) ->
  # Load configuration
  # try
  configs = []
  for config in paths
    location = "#{path.resolve process.cwd(), config}"
    exists = fs.existsSync location
    stat = fs.statSync location if exists
    if exists and stat.isDirectory()
      files = fs.readdirSync location
      for file in files
        continue if file.indexOf('.') is 0
        file = "#{path.resolve location, file}"
        stat = fs.statSync file
        continue if stat.isDirectory()
        configs.push require file
    else
      configs.push require location
  config = merge {}, configs...
  for k, v of config.servers
    v.host ?= k
    v.shortname ?= k.split('.')[0]
    v
  callback null, config
  # catch e
  #   callback Error e
    # process.stderr.write "Fail to load configuration file: #{params.config}\n"
    # console.log e.stack
    # process.exit()
