  
path = require 'path'
fs = require 'fs'
{merge} = require 'mecano/lib/misc'
params = require './params'
params = params.parse()

# Load configuration
try
  configs = []
  for config in params.config
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
  config.servers = for k, v of config.servers
    v.host ?= k
    v
  module.exports = config
catch e
  process.stderr.write "Fail to load configuration file: #{params.config}\n"
  console.log e.stack
  process.exit()
