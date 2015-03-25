
# Bootstrap Mecano

Predefined Mecano functions with context related information.

    mecano = require 'mecano'
    registry = require 'mecano/lib/misc/registry'
    fs = require 'ssh2-fs'
    exports = module.exports = []
    exports.push 'masson/bootstrap/log'
    exports.push 'masson/bootstrap/cache_memory'

For example, this:

```coffee
mecano.execute
  ssh: ctx.ssh
  cmd: 'ls -l'
  stdout: ctx.log.out
  stderr: ctx.log.err
, (err, executed) ->
  ...
```

Is similiar to:

```coffee
ctx.execute
  cmd: 'ls -l'
, (err, executed) ->
  ...
```

    exports.push name: 'Bootstrap # Mecano', required: true, timeout: -1, handler:  (ctx, next) ->
      db = {}
      m = (options) ->
        options.ssh = ctx.ssh if typeof options.ssh is 'undefined'
        options.log = ctx.log if typeof options.log is 'undefined'
        options.stdout = ctx.log.out if typeof options.stdout is 'undefined'
        options.stderr = ctx.log.err if typeof options.stderr is 'undefined'
        options.cache = true
        options.db = db
        options
      functions = for k, v of registry then k
      functions.forEach (action) ->
        ctx[action] = (options, callback) ->
          if action is 'mkdir' and typeof options is 'string'
            options = m destination: options
          if Array.isArray options
            options = for opts, i in options then m opts 
          else
            options = m options
          mecano[action].call null, options, callback
      next null, ctx.PASS

    exports.push name: 'Bootstrap # FS', required: true, timeout: -1, handler:  (ctx) ->
      ctx.fs ?= {}
      [ 'rename', 'chown', 'chmod', 'stat', 'lstat', 'unlink', 'symlink', 
        'readlink', 'unlink', 'mkdir', 'readdir', 'readFile', 'writeFile', 
        'exists', 'createReadStream', 'createWriteStream' ].forEach (fn) ->
        ctx.fs[fn] = ->
          fs[fn].call null, ctx.ssh, arguments...
      ctx.PASS





