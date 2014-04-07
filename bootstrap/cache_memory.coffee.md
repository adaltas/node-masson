---
title: 
layout: module
---

# Cache Memory

    fs = require 'fs'
    each = require 'each'
    misc = require 'mecano/lib/misc'
    mecano = require 'mecano'
    module.exports = []

    module.exports.push (ctx) ->
      ctx.config.bootstrap ?= {}
      ctx.config.bootstrap.cache ?= {}
      ctx.config.bootstrap.cache.location ?= "#{process.cwd()}/tmp"

    module.exports.push name: 'Bootstrap # File Cache', required: true, callback: (ctx, next) ->
      db = {}
      ctx.cache =
        # Whether a key has been previously loaded
        cached: (key) ->
          db[key] isnt 'undefined'
        ###
        Put one or multiple keys into the cache.
        
        ```coffee
        cache.set 'a_key', 'a value', (err) ->
          console.log 'succeed' unless err
        ```

        ```coffee
        cache.set 'key_1': 'value 1', 'key 2': 'value 2', (err) ->
          console.log 'succeed' unless err
        ```
        ###
        set: (key, value, callback) ->
          if arguments.length is 2
            [values, callback] = arguments
            for key, value of values
              db[key] = value
            callback()
          else
            db[key] = value
            callback()
        get: (keys, callback) ->
          s = Array.isArray keys
          keys = [keys] unless s
          data = {}
          for k in keys
            data[k] = db[k] if db[k]?
          if s
          then callback null, data
          else callback null, data[keys[0]]
      next null, ctx.PASS
