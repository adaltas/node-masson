
util = require 'util'
each = require 'each'
multimatch = require '../multimatch'
connect = require 'ssh2-connect'
exec = require 'ssh2-exec'
{merge} = require '../misc'
config = require '../config'
params = require '../params'
context = require '../context'

module.exports = ->
  params = params.parse()
  write = (msg) -> process.stdout.write msg
  config params.config, (err, config) ->
    each config.servers
    .parallel true
    .call (server, next) ->
      return next() if params.hosts? and multimatch(server.host, params.hosts).indexOf(server.host) is -1
      context {}, params, (merge {}, config, server)
      .call ->
        @config.runinfo ?= {}
        @config.runinfo.date ?= new Date
      .call 'masson/bootstrap/log'
      .call 'masson/bootstrap/connection'
      .call (options, callback)->
        exec options.ssh, params.subcommand, (err, stdout, stderr) ->
          write if err
          then "\x1b[31m#{server.host} (exit code #{err.code})\x1b[39m\n"
          else "\x1b[32m#{server.host}\x1b[39m\n"
          write "\n" if stdout.length or stderr.length
          write "\x1b[36m#{stdout.trim()}\x1b[39m\n" if stdout.length
          write "\x1b[35m#{stderr.trim()}\x1b[39m\n" if stderr.length
          write "\n"
          options.ssh.end()
          callback()
    .then (err) ->
      # Done
