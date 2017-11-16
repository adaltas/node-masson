
{exec} = require 'child_process'
server = require 'http-server'
server = require '../server'

module.exports = (config, params) ->
  module.exports[params.action](config, params)

module.exports.start = (config, params) ->
  server.start
    directory: params.directory
    pidfile: params.pidfile
    port: params.port
  , (err, started) ->
    if err then switch err.code
      when 4
        console.error "Port #{params.port} already used"
        process.exit 4
      when 5
        console.error "Directory #{params.directory} does not exists"
        process.exit 5
      else
        console.log "Unkown Error, exit code is #{err.code}"
        process.exit 1
    if started
      console.log 'HTTP Server Started'
      process.exit 0
    else
      console.error 'HTTP Server Already Running'
      process.exit 3

module.exports.stop = (config, params)->
  server.stop
    pidfile: params.pidfile
  , (err, stopped) ->
    if err
      console.error 'HTTP Server Kill Failed'
      process.exit 1
    if stopped
      console.log 'HTTP Server Stopped'
      process.exit 0
    else
      console.error 'HTTP Server Already Stopped'
      process.exit 3

module.exports.status = (config, params) ->
  server.status
    pidfile: params.pidfile
  , (err, status) ->
    if status
      console.error "HTTP Server Started"
      process.exit 0
    else
    console.error "HTTP Server Stopped"
    process.exit 1
