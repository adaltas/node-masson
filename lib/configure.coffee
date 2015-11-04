    util = require 'util'
    EventEmitter = require('events').EventEmitter

    Configure = (host, ctx) ->
      EventEmitter.call @

      setImmediate =>
        for module_name in Object.keys ctx.tree.modules
          module = ctx.tree.modules[module_name]
          module.configure.call ctx, ctx if module.configure
        @emit 'done', host, ctx
      @on 'newListener', (listener) ->
        return

    util.inherits Configure, EventEmitter

    module.exports = (host, ctx) ->
      new Configure host, ctx
