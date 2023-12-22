
import path from 'path'
__dirname = new URL( '.', import.meta.url).pathname

# Enrich module paths
# Module = require 'module'
# for p in Module._nodeModulePaths path.resolve '.'
#   require.main.paths.push p

export default (module) ->
  # module = path.resolve __dirname, "../../#{module.substr 7}" if /^masson\//.test module
  # module = if module.substr(0, 1) is '.'
  # then path.resolve process.cwd(), module
  # else module
  if /\.json$/.test module
    (await import(module, assert: type: 'json')).default
  else
    (await import(module)).default
