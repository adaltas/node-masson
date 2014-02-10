
path = require 'path'
params = require './params'

# Load configuration
try
  module.exports = require "#{path.resolve process.cwd(), params.config}"
catch e
  process.stderr.write "Fail to load configuration file: #{params.config}\n"
  return console.log e
