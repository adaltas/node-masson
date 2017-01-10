
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
    each config.nodes
    .parallel true
    .call (host, node, next) ->
      node.config ?= {}
      node.config.host = host
      return next() if params.hosts? and multimatch(node.config.host, params.hosts).indexOf(node.config.host) is -1
      context [], params, merge {}, config.config, node.config
      .ssh.open config.config.ssh , host: node.config.ip
      .call (options, callback) ->
        console.log 'coucouc'
        exec options.ssh, params.subcommand, (err, stdout, stderr) ->
          write if err
          then "\x1b[31m#{node.config.host} (exit code #{err.code})\x1b[39m\n"
          else "\x1b[32m#{node.config.host}\x1b[39m\n"
          write "\n" if stdout.length or stderr.length
          write "\x1b[36m#{stdout.trim()}\x1b[39m\n" if stdout.length
          write "\x1b[35m#{stderr.trim()}\x1b[39m\n" if stderr.length
          write "\n"
          callback()
      .ssh.close()
    .then (err) ->
      # Done
