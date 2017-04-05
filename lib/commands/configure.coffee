
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
      config params.config, (err, config) ->
        # console.log config
        {contexts} = run params, config
        console.log contexts[0].config
        process.exit()
      return
      # EXAMPLE END
      # behave like the first pass of run command
      # creates a context perserver by executing all configure functions
      valid_extensions = ['json','cson', 'js', 'coffee']
      now = new Date()
      params = params.parse()
      provider = params.format or 'json'
      filename = ''
      params.hosts = [params.hosts] if typeof params.hosts is 'string'
      if params.output?
        filename = params.output
        # If we have one file specified, but no format, we try to autodiscover
        unless params.format? or params.explode
          # Autodiscover format from filename
          output =  params.output.split('.')
          if output.length > 1
            provider = output[output.length-1]
      throw Error "Extension not supported: #{provider}.  Available Extensions: json, cson, js, coffee" unless provider in valid_extensions
      print_export = (obj, path) ->
        wr_stream = fs.createWriteStream path, encoding: 'utf8'
        switch provider
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
      ctxs_output = {}
      # JSON and CSON are suported for now: by default provider is JSON
      config params.config, (err, config) =>
        contexts = {}
        if params.hosts?
          for host in params.hosts
            throw Error "Host #{host} not found" unless host in Object.keys config.servers
        for fqdn, server of config.servers
          ctx = contexts[fqdn] = context contexts, params, (merge {}, config, server)
          ctx.params = params
          ctx.config.runinfo = {}
          ctx.config.runinfo.date = now
        process.on 'uncaughtException', (err) =>
          throw err
        # Discover module inside parent project
        for p in Module._nodeModulePaths path.resolve '.'
          require.main.paths.push p
        each contexts
        .parallel true
        .call (ctx, next) =>
          middlewares = []
          for name in ctx.config.modules
            m = load_module(ctx, name, 'configure')
            middlewares.push m...
          # Export list of modules
          ctx.middlewares = middlewares
          ctx.modules = middlewares.map( (m) -> m.module ).reduce( (p, c) ->
            p.push(c) if p.indexOf(c) < 0; p
          , [] )
          next()
        .call (ctx, next) ->
          call_modules ctx, command: 'configure', ->
            ctxs_output[ctx.config.host] = ctx.config
            next()
        .then (err) ->
          throw err if err
          return console.log ctxs_output if !params.output?
          for fqdn, ctx of ctxs_output
            delete ctxs_output[fqdn] if params.hosts? and fqdn not in params.hosts
            delete ctx.servers
          location = path.resolve process.cwd(), filename
          fs.stat location, (err, exists) ->
            return console.log err if err and err?.code != 'ENOENT'
            if exists
              throw Error 'File already exist: Use --ignore option if you wan\'t to overwrite file' unless params.ignore
            if params.explode
              fs.mkdirSync location
              print_export ctx, "#{location}/#{hostname}.#{provider}" for hostname, ctx of ctxs_output
            else print_export(ctxs_output, location)

    # Configuration
    load_module = (ctx, parent, default_command, filter_command) ->
      middlewares = []
      parent = module: parent if typeof parent is 'string'
      plugin = false
      if not parent.handler or typeof parent.handler is 'string'
        absname = parent.module
        absname = path.resolve process.cwd(), parent.module if parent.module.substr(0, 1) is '.'
        mod = require.main.require absname
        plugin = true if typeof mod is 'function'
        mod = handler: mod unless mod.handler
        throw Error "Invalid handler in #{parent.module}" if typeof mod.handler isnt 'function'
        parent.handler = undefined
        parent[k] ?= v for k, v of mod
      if plugin
        middlewares.push module: parent.module, plugin: true
        commands = parent.handler.call ctx
        return unless commands
        return if commands is ctx
        for command, children of commands
          # when a plugin reference another plugin, we need to filterout other
          # commands while preserving configure
          continue if filter_command and command isnt 'configure' and command isnt filter_command
          continue unless children
          children = [children] unless Array.isArray children
          for child in children
            if typeof child is 'string'
              child = handler: child
            else if typeof child is 'function'
              child = handler: child
            else if not child? or Array.isArray(child) or typeof child isnt 'object'
              throw Error "Invalid child: #{child}"
            if typeof child.handler is 'string'
              child.module = child.handler
            else if typeof child.handler is 'function'
              child.module = parent.module
            else
              throw Error "Invalid handler: #{child.handler}"
            child.command ?= command
            m = load_module(ctx, child, default_command, command)
            middlewares.push m... if m
      else
        # parent.command ?= default_command
        middlewares.push parent
      middlewares

    call_modules = (ctx, params, next) ->
      # Filter by hosts
      return if params.hosts? and (multimatch ctx.config.host, params.hosts).length is 0
      # Action
      ctx.called ?= {}
      for middleware in ctx.middlewares then do (middleware) ->
        return if middleware.plugin
        # return if command isnt 'install' and middleware.command and middleware.command isnt command
        return if middleware.command and middleware.command isnt params.command
        return if not middleware.command and params.command in ['configure', 'prepare']
        return if ctx.called[middleware.module]
        ctx.called[middleware.module] = true
        if middleware.skip
          ctx.emit 'middleware_skip'
          return
        # Load handler
        if typeof middleware.handler is 'string'
          mod = require.main.require middleware.handler
          mod = handler: mod unless mod.handler
          middleware[k] = v for k, v of mod
        # Filter by modules
        return if not middleware.required and params.modules? and (multimatch middleware.module, params.modules).length is 0
        ctx.call -> ctx.emit 'middleware_start', middleware
        ctx.call middleware, (err, status) ->
          ctx.emit 'middleware_stop', middleware, err, status
      ctx.then (err, status) ->
        ctx.emit 'error', err if err
        ctx.emit 'end' if params.end
        next err
