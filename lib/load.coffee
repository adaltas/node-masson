
Module = require 'module'
path = require 'path'
path.isAbsolute ?= (filename) -> filename[0] is '/'

relative_paths = Module._nodeModulePaths path.resolve '.'

module.exports = (filename, parent) ->
  m = new Module filename
  start = filename.substring 0, 2
  if start isnt './' and start isnt '..' and not path.isAbsolute filename
    m.paths = if parent then Module._nodeModulePaths parent else []
    for p in relative_paths
      m.paths.push p
  filename = Module._resolveFilename filename, m
  try
    m.require filename
    Module._cache[filename]
  catch e
    if e instanceof SyntaxError and e.location
      location = path.relative process.cwd(), e.filename
      throw new Error "#{location}:#{e.location.first_line}:#{e.location.first_column} #{e.message}"
    else throw e
