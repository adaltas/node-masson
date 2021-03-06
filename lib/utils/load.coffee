
path = require 'path'

# Enrich module paths
Module = require 'module'
for p in Module._nodeModulePaths path.resolve '.'
  require.main.paths.push p

module.exports = (module) ->
  module = path.resolve __dirname, "../../#{module.substr 7}" if /^masson\//.test module
  module = if module.substr(0, 1) is '.'
  then path.resolve process.cwd(), module
  else module
  require.main.require module
