    config = require '../config'
    params = require '../params'
    tree = require '../tree.coffee'
    context = require '../context.coffee'
    {merge} = require '../misc.coffee'
    each = require 'each'
    configure = require '../configure'
    fs = require 'fs'
    path = require 'path'
    util = require 'util'
    EventEmitter = require('events').EventEmitter
    assign = require 'object-assign'
    CSON = require 'cson'

    # ./bin/ryba configure -o output_file -p JSON
    module.exports = ->
      # behave like the first pass of run command
      # creates a context perserver by executing all configure functions
      contexts = {}
      params = params.parse()
      output = params.output ?= 'report'
      # JSON and CSON are suported for now: by default provider is JSON
      provider = params.provider ?= 'JSON'
      config params.config, (err, config) =>
        do_contexts = ->
          for fqdn, server of config.servers
            ctx = contexts[fqdn] = context (merge {}, config, server), params.command
            ctx.hosts = contexts
            ctx.tree = tree ctx.config.modules
            ctx.modules = Object.keys ctx.tree.modules
          each(contexts)
          .on 'error', (err) ->
            if err.errors
              console.log '\n'
              console.log "#{err.message}\n"
              for err in err.errors
                console.log "#{err.stack?.trim() or err.message}\n"
            else
              console.log "#{err.stack?.trim() or err.message}\n"
          .parallel(true)
          .run (host, ctx, next) =>
            configure host, ctx
            .on 'done', (host, ctx) =>
              done.push host
              out_ctxs[host] = ctx.config
              do_progress()
        do_progress =  ->
          # rate is used for program which may launch configure as child process
          rate = done.length*100/Object.keys(config.servers).length
          process.stdout.write "#{rate}" if process.env.SPAWNED
          return do_write() if Object.keys(config.servers).length == done.length
        do_write =  ->
          switch provider.toUpperCase()
            when 'CSON'
              output = "#{output}.cson"
              location = "#{path.resolve process.cwd(), output}"
              fs.writeFile location, CSON.stringify(out_ctxs), 'utf8', (err, done) ->
                do_end(err, done)
            else
              output = "#{output}.json"
              location = "#{path.resolve process.cwd(), output}"
              fs.writeFile location, JSON.stringify(out_ctxs,null,4), 'utf8', (err, done) ->
                do_end(err)
        do_end = (err) ->
          return err if err
          process.exit(0)
        contexts = {}
        out_ctxs = {}
        done = []
        do_contexts()
