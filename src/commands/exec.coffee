
util = require 'util'
connect = require 'ssh2-connect'
exec = require 'ssh2-exec'
{merge} = require '../misc'
config = require '../config'
params = require '../params'
params = params.parse()

module.exports = ->
  config.servers.forEach (server) ->
    c = merge {}, config.connection,
      username: 'root'
      host: server.ip or server.host
      port: 22
      privateKey: config.connection.private_key
    connect c, (err, ssh) ->
      return util.print "\x1b[31m#{err.message}\x1b[39m\n" if err
      exec ssh, params.subcommand, (err, stdout, stderr) ->
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
        ssh.end()
