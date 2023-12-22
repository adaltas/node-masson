
import path from 'path'
import fs from 'fs/promises'
import {merge} from 'mixme'

export default (paths) ->
  # Load configuration
  configs = []
  for config in paths
    location = "#{path.resolve process.cwd(), config}"
    stat = await fs.stat location
    if stat.isDirectory()
      files = await fs.readdir location
      for file in files
        continue if file.indexOf('.') is 0
        file = "#{path.resolve location, file}"
        stat = await fs.stat file
        continue if stat.isDirectory()
        configs.push require file
    else
      configs.push require location
  config = merge configs...
  for k, v of config.servers
    v.host ?= k
    v.shortname ?= k.split('.')[0]
    v
  return config
