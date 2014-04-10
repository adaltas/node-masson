
util = require 'util'
exec = require 'superexec'
{merge} = require '../misc'
config = require '../config'
params = require '../params'
params = params.parse()

module.exports = ->
  config.servers.forEach (server) ->
    config = merge {}, server,
      host: server.ip or server.host # Prefer ip or host in case dns resolution is not yet active
      username: 'root'
      password: null
    exec params.subcommand, ssh: config, (err, stdout, stderr) ->
      util.print "\n"
      if err
        util.print "\x1b[31m#{server.host}\x1b[39m\n"
        util.print "\n"
        util.print "\x1b[31m#{err.stack or err.message}\x1b[39m"
      else
        util.print "\x1b[32m#{server.host}\x1b[39m\n"
        util.print "\n"
        util.print stdout.trim()
        util.print stderr.trim()
      util.print "\n"
