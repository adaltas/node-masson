
leveldb = require 'level'

module.exports = (path) ->
  db = leveldb path
  put: (key, value, callback) ->
    db.put key, value, callback
  get: (key, callback) ->
    db.get key, callback

