
each = require 'each'
multimatch = require '../utils/multimatch'
exec = require 'ssh2-exec'
merge = require '../utils/merge'
nikita = require 'nikita'

module.exports = (params, config) ->
  config.nikita.no_ssh = true
  write = (msg) -> process.stdout.write msg
  each config.nodes
  .parallel true
  .call (_, node, next) ->
    return next() if params.nodes? and multimatch(node.fqdn, params.nodes).length is 0
    n = nikita merge {}, config.nikita
    n.ssh.open host: node.ip or node.fqdn
    n.call (options, callback) ->
      ssh = @ssh options.ssh
      exec ssh, params.subcommand, (err, stdout, stderr) ->
        write if err
        then "\x1b[31m#{node.fqdn} (exit code #{err.code})\x1b[39m\n"
        else "\x1b[32m#{node.fqdn}\x1b[39m\n"
        write "\n" if stdout.length or stderr.length
        write "\x1b[36m#{stdout.trim()}\x1b[39m\n" if stdout.length
        write "\x1b[35m#{stderr.trim()}\x1b[39m\n" if stderr.length
        write "\n"
        callback()
    n.next (err) ->
      n.ssh.close header: 'SSH Close' #unless params.command is 'prepare' # params.end and
      n.next ->
        process.stdout.write err.message if err
  .next (err) ->
    process.stdout.write err.message if err
    # Done
