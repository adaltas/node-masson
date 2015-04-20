
# Bootstrap Mecano

Enrich the server context with [Mecano] and [File System][nodefs] functions. 

Options send to [Mecano] by the calling user are enriched with default options. 
Such options are "cache", "db", "log", "stdout", "stderr" and "ssh". All the
default function may be created or modified in the user configuration through
the "mecano" configuration property. Setting a value of "null" will disable the
default option.

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

Disable the "ssh" option to run a function locally:

```coffee
ctx.execute
  ssh: null
  cmd: 'ls -l'
, (err, executed) ->
  ...
```

    exports = module.exports = []
    exports.push 'masson/bootstrap/log'
    exports.push 'masson/bootstrap/cache_memory'

## Mecano

[Mecano] provides a set of functions common to system deployments. Functions
share a same API are are designed with idempotence in mind.

Configure the `backup` function.

```json
{
  "mecano": {
    "backup":
      "destination": "/var/tmp/ryba_backups",
      "interval": "week": 1,
      "retention": "count": 10
  }
}
```

Configure the `download` function to support cache.

```json
{
  "mecano": {
    "download":
      "local_cache": true,
      "cache_dir": "./resources/cache"
  }
}
```

    exports.push name: 'Bootstrap # Mecano', required: true, timeout: -1, handler:  (ctx, next) ->
      options = {}
      options.ssh = ctx.ssh
      options.log = ctx.log
      options.stdout = ctx.log.out
      options.stderr = ctx.log.err
      options.cache = true
      options.db = {}
      options[k] = v for k, v of ctx.config.mecano
      mecano @, options
      next null, ctx.PASS

    # exports.push name: 'Bootstrap # Mecano', required: true, timeout: -1, handler:  (ctx, next) ->
    #   # Normalize Configuration
    #   ctx.config.mecano ?= {}
    #   for k, v of registry then ctx.config.mecano[k] ?= {}
    #   db = {}
    #   # Merge Options with Configuration and Default Properties
    #   m = (action, options) ->
    #     for key, value of ctx.config.mecano[action]
    #       if key in ['destination','cache_dir']
    #         options[key] ?= ''
    #         options[key] = path.resolve value, options[key]
    #       else options[key] = value if typeof options[key] is 'undefined'
    #     options.ssh = ctx.ssh if typeof options.ssh is 'undefined'
    #     options.log = ctx.log if typeof options.log is 'undefined'
    #     options.stdout = ctx.log.out if typeof options.stdout is 'undefined'
    #     options.stderr = ctx.log.err if typeof options.stderr is 'undefined'
    #     options.cache = true
    #     options.db = db
    #     options
    #   # Register Mecano functions
    #   functions = for k, v of registry then k
    #   functions.forEach (action) ->
    #     ctx[action] = (options, callback) ->
    #       if action is 'mkdir' and typeof options is 'string'
    #         options = m action, destination: options
    #       if Array.isArray options
    #         options = for opts, i in options then m action, opts 
    #       else
    #         options = m action, options
    #       mecano[action].call null, options, callback
    #   next null, ctx.PASS

## File System

File System functionnalities are imported from the [Node.js `fs`][nodefs] API with
transparent SSH2 transport thanks to the [ssh2-fs] package.

    exports.push name: 'Bootstrap # File System', required: true, timeout: -1, handler:  (ctx) ->
      ctx.fs ?= {}
      [ 'rename', 'chown', 'chmod', 'stat', 'lstat', 'unlink', 'symlink', 
        'readlink', 'unlink', 'mkdir', 'readdir', 'readFile', 'writeFile', 
        'exists', 'createReadStream', 'createWriteStream' ].forEach (fn) ->
        ctx.fs[fn] = ->
          fs[fn].call null, ctx.ssh, arguments...
      ctx.PASS


# Dependencies

    mecano = require 'mecano'
    registry = require 'mecano/lib/misc/registry'
    fs = require 'ssh2-fs'
    path = require 'path'

[mecano]: http://mecano.adaltas.com
[ssh2-fs]: https://github.com/wdavidw/node-ssh2-fs
[nodefs]: http://nodejs.org/api/fs.html

