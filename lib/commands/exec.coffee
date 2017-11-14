
each = require 'each'
multimatch = require '../utils/multimatch'
exec = require 'ssh2-exec'
merge = require '../utils/merge'
nikita = require 'nikita'

module.exports = (config, params) ->
  config.nikita.no_ssh = true
  write = (msg) -> process.stdout.write msg
  each config.nodes
  .parallel true
  .call (_, node, next) ->
    return next() if params.hosts? and multimatch(node.fqdn, params.hosts).length is 0
    n = nikita merge {}, config.nikita
    n.ssh.open host: node.ip or node.fqdn
    n.call (options, callback) ->
      exec options.ssh, params.subcommand, (err, stdout, stderr) ->
        write if err
        then "\x1b[31m#{node.fqdn} (exit code #{err.code})\x1b[39m\n"
        else "\x1b[32m#{node.fqdn}\x1b[39m\n"
        write "\n" if stdout.length or stderr.length
        write "\x1b[36m#{stdout.trim()}\x1b[39m\n" if stdout.length
        write "\x1b[35m#{stderr.trim()}\x1b[39m\n" if stderr.length
        write "\n"
        callback()
    n.then (err) ->
      n.ssh.close()
      next err
  .next (err) ->
    process.stdout.write err.message if err
    # Done
