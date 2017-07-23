
each = require 'each'
multimatch = require '../multimatch'
exec = require 'ssh2-exec'
{merge} = require '../misc'
config = require '../config'
params = require '../params'
nikita = require 'nikita'

module.exports = ->
  params = params.parse()
  write = (msg) -> process.stdout.write msg
  config params.config, (err, config) ->
    each config.nodes
    .parallel true
    .call (host, node, next) ->
      node.config ?= {}
      node.config = merge {}, config.config, node.config
      return next() if params.hosts? and multimatch(node.config.host, params.hosts).indexOf(node.config.host) is -1
      nikita()
      .ssh.open ssh: merge {}, node.config.nikita?.ssh, host: node.config.ip or node.config.host
      .call (options, callback) ->
        exec options.ssh, params.subcommand, (err, stdout, stderr) ->
          write if err
          then "\x1b[31m#{host} (exit code #{err.code})\x1b[39m\n"
          else "\x1b[32m#{host}\x1b[39m\n"
          write "\n" if stdout.length or stderr.length
          write "\x1b[36m#{stdout.trim()}\x1b[39m\n" if stdout.length
          write "\x1b[35m#{stderr.trim()}\x1b[39m\n" if stderr.length
          write "\n"
          callback()
      .ssh.close()
      .then next
    .then (err) ->
      # Done
