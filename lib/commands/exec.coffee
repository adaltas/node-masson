
each = require 'each'
multimatch = require '../utils/multimatch'
exec = require 'ssh2-exec'
{merge} = require 'mixme'
nikita = require '@nikitajs/core'
exec_sync = require('child_process').execSync
env = require('process').env
fs = require('fs')

module.exports = ({params}, config) ->
  if not params.subcommand? or params.subcommand.length == 0
    if not 'EDITOR' in env or env['EDITOR'] == ""
      console.log("Please set your EDITOR env variable to the text editor of your choice\ne.g: export EDITOR=vi")
      return
    fs.writeFileSync('/tmp/masson_exec', '#!/bin/sh\n# Edit your Masson script to execute')
    exec_sync(env['EDITOR']+' /tmp/masson_exec', {stdio: 'inherit', detached: true})
    cmd = fs.readFileSync('/tmp/masson_exec', 'utf8');
    fs.unlinkSync('/tmp/masson_exec')
  else
    cmd = params.subcommand.map((c) -> "\"#{c}\"").join ' '

  config.nikita.no_ssh = true
  write = (msg) -> process.stdout.write msg
  each config.nodes
  .parallel true
  .call (_, node, callback) ->
    return callback() if params.nodes? and multimatch(node.fqdn, params.nodes).length is 0
    for tag in params.tags or {}
      [key, value] = tag.split '='
      return callback() if multimatch(node.tags[key] or [], value.split(',')).length is 0
    n = nikita merge config.nikita
    n.ssh.open host: node.ip or node.fqdn, node.ssh
    n.call ({options}, callback) ->
      isRoot = config.nikita.ssh.username is 'root' or not config.nikita.ssh.username
      @system.execute
        relax: true
        sudo: not isRoot
        cmd: cmd
      , (err, {stdout, stderr}) ->
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
