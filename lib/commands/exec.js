
var exec_sync,
  indexOf = [].indexOf;

import each from 'each';

import multimatch from '../utils/multimatch';

import exec from 'ssh2-exec';

import {
  merge
} from 'mixme';

import nikita from '@nikitajs/core';

import child from 'child_process';

import process from 'process';

import fs from 'fs';

exec_sync = child.execSync;

export default async function({params}, config) {
  var command, nodes, ref, write;
  if ((params.subcommand == null) || params.subcommand.length === 0) {
    if ((ref = !'EDITOR', indexOf.call(process.env, ref) >= 0) || process.env['EDITOR'] === "") {
      console.log("Please set your EDITOR env variable to the text editor of your choice\ne.g: export EDITOR=vi");
      return;
    }
    fs.writeFileSync('/tmp/masson_exec', '#!/bin/sh\n# Edit your Masson script to execute');
    exec_sync(process.env['EDITOR'] + ' /tmp/masson_exec', {
      stdio: 'inherit',
      detached: true
    });
    command = fs.readFileSync('/tmp/masson_exec', 'utf8');
    fs.unlinkSync('/tmp/masson_exec');
  } else {
    command = params.subcommand.map(function(c) {
      return `\"${c}\"`;
    }).join(' ');
  }
  write = function(msg) {
    return process.stdout.write(msg);
  };
  nodes = Object.values(config.nodes);
  return (await each(nodes, true, async function(node) {
    var i, key, len, ref1, tag, value;
    if ((params.nodes != null) && multimatch(node.fqdn, params.nodes).length === 0) {
      return;
    }
    ref1 = params.tags || {};
    for (i = 0, len = ref1.length; i < len; i++) {
      tag = ref1[i];
      [key, value] = tag.split('=');
      if (multimatch(node.tags[key] || [], value.split(',')).length === 0) {
        return;
      }
    }
    return (await nikita({
      $ssh: merge({
        host: node.ip || node.fqdn
      }, node.ssh)
    }, async function({ssh}) {
      var error, stderr, stdout;
      ({error, stdout, stderr} = (await this.execute({
        $relax: true,
        $sudo: true,
        command: command
      })));
      write(error ? `\x1b[31m${node.fqdn} (exit code ${error.exit_code})\x1b[39m\n` : `\x1b[32m${node.fqdn}\x1b[39m\n`);
      if ((stdout || error.stdout).length || (stderr || error.stderr).length) {
        write("\n");
      }
      if ((stdout || error.stdout).length) {
        write(`\x1b[36m${(stdout || error.stdout).trim()}\x1b[39m\n`);
      }
      if ((stderr || error.stderr).length) {
        write(`\x1b[35m${(stderr || error.stderr).trim()}\x1b[39m\n`);
      }
      return write("\n");
    }));
  }).catch(function(err) {
    return process.stderr.write(`${err.message}\n`);
  }));
};
