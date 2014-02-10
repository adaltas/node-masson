
util = require 'util'
exec = require 'superexec'
{merge} = require 'mecano/lib/misc'
config = require '../config'
params = require '../params'
params = params.parse()

module.exports = ->
  for server in config.servers
    config = merge {}, server,
      username: 'root'
      password: null
    exec params.subcommand, ssh: config, (err, stdout, stderr) ->
      util.print "\n"
      if err
        util.print "\x1b[31m#{server.host}\x1b[39m\n"
      else
        util.print "\x1b[32m#{server.host}\x1b[39m\n"
      util.print "\n"
      util.print stdout.trim()
      util.print stderr.trim()
      util.print "\n"
