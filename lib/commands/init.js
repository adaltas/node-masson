
// # Masson Init `masson init [...]`

// ```
// masson init           Create a project with a default layout and configuration
//   -d --debug          Print debug output
//   -i --description    Project description
//   -l --latest         Enable a development environment such as using latest git for package dependencies.
//   -n --name           Project name
//   -p --path           Path to the project directory, default to the current directory.
// ```

// Example:

// ```
// masson init \
//   -n 'ryba-cluster' \
//   -p './cluster' \
//   -l -d
// ```
import params from 'masson/params';

import fs from 'fs';

import nikita from '@nikitajs/core';

import readline from 'readline';

export default function({params}, config) {
  var rl;
  if (params.path == null) {
    params.path = process.cwd();
  }
  if (params.description == null) {
    params.description = `Description of ${params.name} application.`;
  }
  rl = readline.createInterface(process.stdin, process.stdout);
  rl.setPrompt('');
  rl.on('SIGINT', process.exit);
  return nikita({
    debug: params.debug
  }).call(function(_, callback) {
    return fs.stat(`${params.path}`, function(err, stat) {
      if ((err != null ? err.code : void 0) === 'ENOENT') {
        return callback(null, true);
      } else if (err) {
        return callback(err);
      } else if (stat.isDirectory()) {
        return fs.stat(`${params.path}/.git`, function(err, stat) {
          if (err || !(stat != null ? stat.isDirectory() : void 0)) {
            return callback(null, true);
          } else {
            if (!err) {
              rl.write("Directory already under GIT\n");
            }
            return callback(null, false);
          }
        });
      } else {
        if (!err) {
          rl.write(`Invalid directory '${params.path}'\n`);
        }
        return callback(null, false);
      }
    });
  }, function(err, status) {
    if (!(err || status)) {
      return this.end();
    }
  }).mkdir({
    header: 'Project Directory',
    target: `${params.path}`
  }, function(err, status) {
    if (err || !status) {
      return;
    }
    return rl.write(`Directory '${params.path}' created\n`);
  }).write({
    target: `${params.path}/bin/ryba`,
    content: `#!/bin/bash
cd \`dirname "\${BASH_SOURCE}"\`/..
./node_modules/.bin/ryba -c ./conf/*.coffee $@`,
    mode: 0o0755,
    eof: true
  }, function(err, status) {
    if (err || !status) {
      return;
    }
    return rl.write("GIT ignore created\n");
  }).write({
    target: `${params.path}/bin/vagrant`,
    content: `#!/bin/bash
cd $( dirname "\${BASH_SOURCE}" )/../conf
vagrant $@`,
    mode: 0o0755,
    eof: true
  }, function(err, status) {
    if (err || !status) {
      return;
    }
    return rl.write("GIT ignore created\n");
  }).write({
    target: `${params.path}/.gitignore`,
    content: `.*
!.gitignore
/node_modules`,
    eof: true
  }, function(err, status) {
    if (err || !status) {
      return;
    }
    return rl.write("GIT ignore created\n");
  }).write({
    target: `${params.path}/package.json`,
    content: `{
  "name": "${params.name}",
  "version": "0.0.0",
  "description": "${params.description}",
  "dependencies": {
    "coffeescript": "^2.0.2",
    "masson": "${!params.latest ? '0.1.3' : 'https://github.com/adaltas/node-masson.git#HEAD'}",
    "ryba": "${!params.latest ? '0.0.6' : 'https://github.com/ryba-io/ryba.git#HEAD'}",
    "ryba-repos": "${!params.latest ? '0.0.2' : 'https://github.com/ryba-io/ryba-repos.git#HEAD'}"
  }
}`,
    eof: true
  }, function(err, status) {
    if (err || !status) {
      return;
    }
    return rl.write("Package definition created\n");
  }).touch({
    target: `${params.path}/cache/.gitignore`
  }, function(err, status) {
    if (err || !status) {
      return;
    }
    return rl.write("Cache directory created\n");
  }).write({
    target: `${params.path}/conf/config.coffee`,
    content: `module.exports =
  connection:
    private_key: \"\"\"
    -----BEGIN RSA PRIVATE KEY-----
    MIIEogIBAAKCAQEArBDFt50aN9jfIJ629pRGIMA1fCMb9RyTHt9A+jx3FOsIOtJs
    eaBIpv98drbFVURr+cUs/CrgGVk5k2NIeiz0bG4ONV5nTwx38z5CzqLb7UryZS3i
    a/TS14fWOxvWTRR27R71ePX90G/ZIReKFeTrucw9y9Pl+xAzsmeblRwLBxv/SWBX
    Uai2mHAZaejlG9dGkn9f2n+oPmbgk6krLMCjLhlNBnkdroBNSXGA9ewLPFF4y54Q
    kBqmG3eLzCqAKAzwyJ5PpybtNGAWfN81gY/P5LBzC66WdtEzpwsYAv1wCioqggtg
    xVZN2s0ajxQrCxahRkXstBI2IDcm2qUTxaDbUwIDAQABAoIBAFruOi7AvXxKBhCt
    D6/bx/vC2AEUZM/yG+Wywhn8HkpVsvGzBlR4Wiy208XA7SQUlqNWimFxHyEGQCEd
    1M2MOFedCbE2hI4H3tQTUSb2dhc/Bj5mM0QuC8aPKK3wFh6B9B93vu3/wfSHR03v
    rK/JXLHBt96hyuYVN9zOWDBCs6k7SdQ2BcsQLiPg6feTsZelJDuO+DO65kKLMiz3
    mNPThErklRaKovNk47LSYakk6gsJXrpG6JWQ6nwsRenwplDwZ8Zs9mlRi7f3nChM
    3I1WlISN8y2kcQBQ94YZKk8wzH/lzmxsabcLa5ETNubxQ6ThDu1oYUIIUsQyNPm+
    DkW0VwECgYEA5MttelspKexWS39Y3sQYvZ/v8VZBQl4tRbpUWWc+PNEtcEwOBza/
    H4jBWYd2eWKTApJT1st58E4b34Mv88nQVElLb3sE7uJMkihPyNpABGbCvr63hDYw
    PyL53nKaPelY/aDnL0F8LmREfdKw/uy6+UChgkPfdo2VVk1oyvsZaRMCgYEAwIZ+
    lCmeXQ4mU6uxO+ChhDn7zw9rR5qlCyfJiLPe2lV20vaHV5ZfKIWGegsVJSpFr2ST
    5ghh+FVIneoNRtTHEKwNWCK7I6qeF+WAaci+KsLQigJQHsw58n9cdA7wHHc475n/
    pf7efoPcvk6qYOS2mpDgC87m+o3C4Dyspqp9TMECgYA4/ed+dBjT5Zg1ZDp5+zUC
    f0Wgw1CsPJNgbCK4xnv9YEnGUFuqNlvzefhX2eOMJx7hpBuYRMVSM9LDoYUfYCUx
    6bQNyAIZk2tpePsu2BbcQdC+/PjvySPJhmfhnoCHbYoKW7tazSAm2jkpcoM+bS/C
    CPRyY3/Voz0Q62VwMo5I2wKBgB4mMbZUGieqapgZwASHdeO2DNftKzioYAYyMd5F
    hLWeQqBg2Or/cmFvH5MHH0WVrBn+Xybb0zPHbzrDh1a7RX035FMUBUhdlKpbV1O5
    iwY5Qd0K5a8c/koaZckK+dELXpAvBpjhI8ieL7hhq07HIk1sOJnAye0cvBLPjZ3/
    /uVBAoGAVAs6tFpS0pFlxmg4tfGEm7/aP6FhyBHNhv2QGluw8vv/XVMzUItxGIef
    HcSMWBm08IJMRJLgmoo1cuQv6hBui7JpDeZk/20qoF2oZW9lJ9fdRObJqi61wufP
    BNiriqexq/eTy2uF9RCCjLItWxUscVMlVt4V65HLkCF5WxCQw+o=
    -----END RSA PRIVATE KEY-----
    \"\"\"
    public_key: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsEMW3nRo32N8gnrb2lEYgwDV8Ixv1HJMe30D6PHcU6wg60mx5oEim/3x2tsVVRGv5xSz8KuAZWTmTY0h6LPRsbg41XmdPDHfzPkLOotvtSvJlLeJr9NLXh9Y7G9ZNFHbtHvV49f3Qb9khF4oV5Ou5zD3L0+X7EDOyZ5uVHAsHG/9JYFdRqLaYcBlp6OUb10aSf1/af6g+ZuCTqSsswKMuGU0GeR2ugE1JcYD17As8UXjLnhCQGqYbd4vMKoAoDPDInk+nJu00YBZ83zWBj8/ksHMLrpZ20TOnCxgC/XAKKiqCC2DFVk3azRqPFCsLFqFGRey0EjYgNybapRPFoNtT Ryba Hadoop'
    bootstrap:
      username: 'vagrant'
      password: 'vagrant'
  nikita:
    domain: true
    cache_dir: "./cache"
  servers:
    'node1.ryba':
      ip: '10.10.10.11'
      modules: [
        'masson/bootstrap/log'
        'masson/bootstrap/connection'
        './lib/helloworld'
      ]`,
    eof: true
  }, function(err, status) {
    if (err || !status) {
      return;
    }
    return rl.write("Configuration file created\n");
  }).write({
    target: `${params.path}/lib/helloworld.coffee.md`,
    content: `# Helloworld

A simple module to write a file in the root folder and execute a command.

    module.exports = (ctx) ->
      @config.helloword ?= {}
      @config.helloword.content = 'Helloworld'

## Install

Write a file.

      install: ->
        @file
          target: "/root/helloword"
          content: "Print \#{@config.helloword.content}"

## Check

Compare the file content with its expected value.

      check: ->
        @system.execute
          cmd: "[[ \`cat /root/helloword\` == '@config.helloword.content' ]]"`,
    eof: true
  }).write({
    target: `${params.path}/conf/VagrantFile`,
    content: `box = "centos65-x86_64-50g"
Vagrant.configure("2") do |config|
  config.vm.synced_folder ".", "/vagrant", disabled: true
  # Virtualbox Configuration
  config.vm.provider :virtualbox do |vb|
    config.vbguest.no_remote = true
    config.vbguest.auto_update = false
  end
  # Libvirt Configuration
  config.vm.provider :libvirt do |libvirt|
    libvirt.storage_pool_name="ryba-cluster"
    libvirt.uri="qemu:///system"
  end
  config.vm.define :node1 do |node|
    node.vm.box = box
    node.vm.hostname = "node1.ryba"
    node.vm.network :private_network, ip: "10.10.10.11"
    node.vm.network :forwarded_port, guest: 22, host: 24011, auto_correct: true
    node.vm.provider "virtualbox" do |d|
      d.customize ["modifyvm", :id, "--memory", 1024]
      d.customize ["modifyvm", :id, "--cpus", 2]
      d.customize ["modifyvm", :id, "--ioapic", "on"]
    end
    node.vm.provider "libvirt" do |d|
      d.memory = 1024
      d.cpus = 2
      d.graphics_port = 5911
    end
  end
end`,
    eof: true
  }, function(err, status) {
    if (err || !status) {
      return;
    }
    return rl.write("Vagrant file created\n");
  }).write({
    header: 'Log Directory',
    target: `${params.path}/log/.gitignore`,
    content: `*
!.gitignore`,
    eof: true
  }, function(err, status) {
    if (err || !status) {
      return;
    }
    return rl.write("GIT initialized\n");
  }).execute({
    cmd: `git init
git add .gitignore package.json cache/.gitignore conf/config.coffee log/.gitignore conf/VagrantFile
git commit -m 'Project initialization'`,
    cwd: `${params.path}`
  }).execute({
    cmd: "npm install",
    cwd: `${params.path}`
  }).next(function(err, status) {
    var ref;
    if (err) {
      rl.write(`${((ref = err.stack) != null ? ref.trim() : void 0) || err.message}\n`);
    } else if (status) {
      rl.write('Project initialized\n');
    }
    rl.close();
    return callback(err);
  });
};
