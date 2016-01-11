
    config = require '../config'
    params = require '../params'
    tree = require '../tree'
    context = require '../context'
    {merge} = require '../misc'
    each = require 'each'
    fs = require 'fs'
    path = require 'path'
    util = require 'util'
    EventEmitter = require('events').EventEmitter
    CSON = require 'cson'

    # ./bin/ryba configure -o output_file -p JSON
    module.exports = ->
      # behave like the first pass of run command
      # creates a context perserver by executing all configure functions
      params = params.parse()
      provider = 'json'
      filename = ''
      extensions = ['json','cson', 'js', 'coffee']
      if params.output?
        output =  params.output.split('.')
        if output.length > 1
          provider = output[output.length-1]
          throw Error "Extension not support: .#{provider}  Available Extensions: .json, .cson, .js, .coffee" unless provider in extensions
          filename = params.output
        else
          filename = "#{params.output}.#{provider}"
      ctxs_output = {}
      # JSON and CSON are suported for now: by default provider is JSON
      config params.config, (err, config) =>
        contexts = {}
        for fqdn, server of config.servers
          ctx = contexts[fqdn] = context (merge {}, config, server), params.command
          ctx.hosts = contexts
          ctx.tree = tree ctx.config.modules
          ctx.modules = Object.keys ctx.tree.modules
        for fqdn, ctx of contexts
          for module in Object.keys ctx.tree.modules
            module = ctx.tree.modules[module]
            module.configure.call ctx, ctx if module.configure
          ctxs_output[fqdn] = ctx.config
        return console.log ctxs_output if !params.output?
        for fqdn, ctx of ctxs_output
          delete ctx.servers
        location = path.resolve process.cwd(), filename
        fs.stat location, (err, exists) ->
          return console.log err if err and err?.code != 'ENOENT'
          if exists
            return throw Error 'File already exist: Use --ignore option if you wan\'t to overwrite file' unless params.ignore
          console.log location
          wr_stream = fs.createWriteStream location, encoding: 'utf8'
          switch provider
            when 'cson'
              wr_stream.write CSON.stringify(ctxs_output, null, 2)
            when 'json'
              wr_stream.write JSON.stringify(ctxs_output, null, 2)
            when 'js'
              wr_stream.write "module.exports = servers = #{JSON.stringify ctxs_output, null, 2}"
            when 'coffee'
              wr_stream.write "module.exports = servers: #{CSON.stringify ctxs_output, null, 2}"
          wr_stream.end()
