---
title: 
layout: module
---

# Mecano

Predefined Mecano functions with context related information.

    mecano = require 'mecano'
    module.exports = []

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

    module.exports.push name: 'Bootstrap # Mecano', required: true, timeout: -1, callback:  (ctx, next) ->
      ctx.cache.get ['mecano:installed', 'mecano:updates'], (err, cache) ->
        m = (action, options) ->
          options.ssh = ctx.ssh if typeof options.ssh is 'undefined'
          options.log = ctx.log if typeof options.log is 'undefined'
          options.stdout = ctx.log.out if typeof options.stdout is 'undefined'
          options.stderr = ctx.log.err if typeof options.stderr is 'undefined'
          options.installed = cache['mecano:installed']
          options.updates = cache['mecano:updates']
          options
        [ 'chmod', 'chown', 'copy', 'download', 'execute', 
          'extract', 'git', 'ini', 'krb5_addprinc', 'krb5_delprinc', 
          'ldap_acl', 'ldap_index', 'ldap_schema', 'link', 'mkdir', 
          'move', 'remove', 'render', 'service', 'touch', 
          'upload', 'write'
        ].forEach (action) ->
          ctx[action] = (goptions, options, callback) ->
            if arguments.length is 2
              callback = options
              options = goptions
              goptions = {parallel: 1}
            if action is 'mkdir' and typeof options is 'string'
              options = m action, destination: options
            if Array.isArray options
              for opts, i in options
                options[i] = m action, opts
            else
              options = m action, options
            if action is 'service'
              mecano[action].call null, options, (err) ->
                return callback.apply null, arguments if err
                cache['mecano:installed'] = arguments[2] 
                cache['mecano:updates'] = arguments[3] 
                ctx.cache.set
                  'mecano:installed': arguments[2] 
                  'mecano:updates': arguments[3]
                , (err) ->
                  callback.apply null, arguments
            else
              mecano[action].call null, goptions, options, callback
        next null, ctx.PASS





