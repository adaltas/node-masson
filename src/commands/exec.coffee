
import each from 'each'
import multimatch from '../utils/multimatch'
import exec from 'ssh2-exec'
import {merge} from 'mixme'
import nikita from '@nikitajs/core'
import child from 'child_process'
import env from('process').env
import fs from('fs')
const exec_sync = child.execSync

export default ({params}, config) ->
  if not params.subcommand? or params.subcommand.length == 0
    if not 'EDITOR' in env or env['EDITOR'] == ""
      console.log("Please set your EDITOR env variable to the text editor of your choice\ne.g: export EDITOR=vi")
      return
    fs.writeFileSync('/tmp/masson_exec', '#!/bin/sh\n# Edit your Masson script to execute')
    exec_sync(env['EDITOR']+' /tmp/masson_exec', {stdio: 'inherit', detached: true})
    command = fs.readFileSync('/tmp/masson_exec', 'utf8');
    fs.unlinkSync('/tmp/masson_exec')
  else
    command = params.subcommand.map((c) -> "\"#{c}\"").join ' '
  write = (msg) -> process.stdout.write msg
  nodes = Object.values(config.nodes)
  await each nodes, true, (node) ->
    return if params.nodes? and multimatch(node.fqdn, params.nodes).length is 0
    for tag in params.tags or {}
      [key, value] = tag.split '='
      return if multimatch(node.tags[key] or [], value.split(',')).length is 0
    await nikita
      $ssh: merge
        host: node.ip or node.fqdn
        node.ssh
    , ({ssh}) ->
      {error, stdout, stderr} = await @execute
        $relax: true
        $sudo: true
        command: command
      write if error
      then "\x1b[31m#{node.fqdn} (exit code #{error.exit_code})\x1b[39m\n"
      else "\x1b[32m#{node.fqdn}\x1b[39m\n"
      write "\n" if (stdout || error.stdout).length or (stderr || error.stderr).length
      write "\x1b[36m#{(stdout || error.stdout).trim()}\x1b[39m\n" if (stdout || error.stdout).length
      write "\x1b[35m#{(stderr || error.stderr).trim()}\x1b[39m\n" if (stderr || error.stderr).length
      write "\n"
  .catch (err) ->
    process.stderr.write "#{err.message}\n"
