
Module = require 'module'
path = require 'path'

# Need to look at the function "exports.eval" 
# in "coffee-script/src/coffee-script.coffee"

module.exports = (filename) ->
  m = new Module filename
  start = filename.substring 0, 2
  if start isnt './' and start isnt '..'
    m.paths = Module._nodeModulePaths path.resolve '.'
    # absfilename = Module._findPath filename, m.paths
    # unless absfilename
    #   err = new Error "Cannot find module '#{filename}'"
    #   err.code = 'MODULE_NOT_FOUND'
    #   throw err
  # else
  #   absfilename = path.resolve '.', filename
  filename = Module._resolveFilename filename, m
  try
    m.require filename
    Module._cache[filename]
  catch e
    if e instanceof SyntaxError and e.location
      location = path.relative process.cwd(), e.filename
      throw new Error "#{location}:#{e.location.first_line}:#{e.location.first_column} #{e.message}"
    else throw e
