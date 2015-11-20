
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
      provider = params.provider ?= 'JSON'
      output =  if params.output then  "#{params.output}.#{provider.toLowerCase()}" else ''
      provider = provider.toUpperCase()
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
        return console.log ctxs_output if output == ''
        for fqdn, ctx of ctxs_output
          delete ctx.servers
        switch provider
          when 'CSON'
            location = "#{path.resolve process.cwd(), output}"
            fs.writeFile location, CSON.stringify(ctxs_output), 'utf8', (err, done) ->
              return  if err then err else process.exit(0)
          else
            location = "#{path.resolve process.cwd(), output}"
            fs.writeFile location, JSON.stringify(ctxs_output,null,4), 'utf8', (err, done) ->
              return  if err then err else process.exit(0)
