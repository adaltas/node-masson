
    config = require '../config'
    params = require '../params'
    context = require '../context'
    {merge} = require '../misc'
    each = require 'each'
    fs = require 'fs'
    path = require 'path'
    util = require 'util'
    EventEmitter = require('events').EventEmitter
    CSON = require 'cson'
    string = require 'nikita/lib/misc/string'
    Module = require 'module'
    run = require '../run'

    # ./bin/ryba configure -o output_file -p JSON
    module.exports = ->
      # EXAMPLE START
      params = params.parse()
      params.output ?= 'export'
      params.format ?= 'cson'
      params.output = path.resolve process.cwd(), params.output
      params.hosts = [params.hosts] if typeof params.hosts is 'string'
      throw Error "Format not supported: #{params.format}" unless params.format in ['json','cson', 'js', 'coffee']
      # Print host cfg on path
      print_object = (obj, path) ->
        wr_stream = fs.createWriteStream path, encoding: 'utf8'
        switch params.format
          when 'cson'
            wr_stream.write CSON.stringify(obj, null, 2)
          when 'json'
            wr_stream.write JSON.stringify(obj, null, 2)
          when 'js'
            wr_stream.write "module.exports = #{JSON.stringify obj, null, 2}"
          when 'coffee'
            # adds 2 spaces to the stringified object for CSON indentation before writing it
            content = (string.lines CSON.stringify(obj, null, 2)).join("\n  ")
            wr_stream.write "module.exports =\n  #{content}"
        wr_stream.end()
        console.log path
      # Print contexts
      print_ctxs = (ctxs) ->
        ctxs = ctxs.filter((c) -> c.config.host in params.hosts) if params.hosts?
        confs = ctxs.map((c) -> config: c.config, services: c.services)
        for c in confs
          print_object c, "#{params.output}/#{c.config.host}.#{params.format}"
      # Call config
      config params.config, (err, config) ->
        # console.log config
        {contexts} = run params, config
        stat = fs.stat params.output, (err, stat) ->
          if stat
            throw Error 'Cannot create directory: file already exists' unless stat.isDirectory()
            print_ctxs contexts
          else fs.mkdir params.output, (err) ->
            throw err if err
            print_ctxs contexts
