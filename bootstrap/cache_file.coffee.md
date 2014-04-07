---
title: 
layout: module
---

# Cache File

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
      ctx.config.bootstrap.cache ?= {}
      {location} = ctx.config.bootstrap.cache
      location = "#{location}/#{ctx.config.host}"
      ctx._cache ?= {}
      mecano.mkdir
        destination: location
      , (err, created) ->
        ctx.cache =
          cached: (key) ->
            hash = misc.string.hash key
            ctx._cache[hash]
          set: (key, value, callback) ->
            set = (key, value, callback) ->
              hash = misc.string.hash key
              value = JSON.stringify value
              fs.writeFile "#{location}/#{hash}", value, callback
            if arguments.length is 2
              [values, calback] = arguments
              each(Object.keys(values))
              .on 'item', (key, next) ->
                set key, values[key], next
              .on 'both', (err) ->
                calback err
            else
              set key, value, callback
          get: (keys, callback) ->
            s = Array.isArray keys
            keys = [keys] unless s
            data = {}
            each(keys)
            .on 'item', (key, next) ->
              hash = misc.string.hash key
              if ctx._cache[key]
                data[key] = ctx._cache[hash] if ctx._cache[hash]
                return next()
              fs.readFile "#{location}/#{hash}", (err, value) ->
                return next err if err and err.code isnt 'ENOENT'
                value = JSON.parse value if value
                data[key] = if err then null else value
                next()
            .on 'error', (err) ->
              callback err
            .on 'end', ->
              if s
              then callback null, data
              else callback null, data[keys[0]]
        next null, ctx.PASS
