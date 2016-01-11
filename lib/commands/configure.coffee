
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
      provider = 'JSON'
      output = []
      extensions = ['JSON','CSON', 'JS', 'COFFEE']
      if params.output?
        output =  params.output.split('.')
        if output.length > 1
          return throw Error "Extension not support: .#{output[1]}  Available Extensions: .json, .cson, .js, .coffee" if output[1].toUpperCase() not in extensions
          provider = output[1].toUpperCase()
        output[1] = ".#{provider.toLowerCase()}"
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
        location = "#{path.resolve process.cwd(), "#{output[0]}#{output[1]}"}"
        fs.stat location, (err, exists) ->
          return console.log err if err and err?.code != 'ENOENT'
          if exists
            return throw Error 'File already exist: Use --ignore option if you wan\'t to overwrite file' unless params.ignore
          console.log location
          wr_stream = fs.createWriteStream location, encoding: 'utf8'
          switch provider
            when 'CSON'
              wr_stream.write CSON.stringify(ctxs_output)
            when 'JSON'
              wr_stream.write JSON.stringify(ctxs_output,null,4)
            when 'JS'
              wr_stream.write "module.exports = servers = #{JSON.stringify(ctxs_output,null,4)}"
            when 'COFFEE'
              wr_stream.write "module.exports = servers: #{ CSON.stringify(ctxs_output)}"
          wr_stream.end()
