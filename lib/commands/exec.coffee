
util = require 'util'
each = require 'each'
multimatch = require 'multimatch'
connect = require 'ssh2-connect'
exec = require 'ssh2-exec'
{merge} = require '../misc'
config = require '../config'
params = require '../params'

module.exports = ->
  params = params.parse()
  config params.config, (err, config) ->
    each config.servers
    .parallel true
    .on 'item', (server, next) ->
      return next() if params.hosts? and multimatch(server.host, params.hosts).indexOf(server.host) is -1
      connection = merge {}, config.connection, server.connection
      connection.username ?= 'root'
      connection.host ?= connection.ip or server.ip or server.host
      connection.port ?= 22
      connection.private_key_location ?= '~/.ssh/id_rsa'
      connect connection, (err, ssh) ->
        write = (msg) -> process.stdout.write msg
        return write "\x1b[31m#{err.message}\x1b[39m\n" if err
        exec ssh, params.subcommand, (err, stdout, stderr) ->
          write if err
          then "\x1b[31m#{server.host} (exit code #{err.code})\x1b[39m\n"
          else "\x1b[32m#{server.host}\x1b[39m\n"
          write "\n" if stdout.length or stderr.length
          write "\x1b[36m#{stdout.trim()}\x1b[39m\n" if stdout.length
          write "\x1b[35m#{stderr.trim()}\x1b[39m\n" if stderr.length
          write "\n"
          ssh.end()
    .on 'both', (err) ->
      # Done
