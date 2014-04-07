---
title: 
layout: module
---

    module.exports = []
    module.exports.push 'masson/bootstrap/'

# Users

A module to create and manage unix users.

## Configuration

    module.exports.push module.exports.configure = (ctx) ->
      ctx.config.users ?= []
      for user in ctx.config.users
        user.home ?= if user.username is 'root' then '/root' else unless user.system then "/home/#{user.username}"
        user.home = "/home/#{user.username}" if user.home is true
        user.shell = '/bin/bash' if user.shell is true

## Users creation

Internally, this use the `useradd` command.

    module.exports.push name: 'Users', callback: (ctx, next) ->
      # TODO: deal with password
      cmds = []
      for user in ctx.config.users
        return next err 'Required property "username"' unless user.username
        cmd = 'useradd'
        cmd += " #{user.username}"
        cmd += " -c #{user.comment}" if user.comment
        cmd += " -d #{user.home}" if user.home
        cmd += " -e #{user.expiredate}" if user.expiredate
        cmd += " -f #{user.inactive}" if user.inactive
        cmd += " -g #{user.gid}" if user.gid
        cmd += " -G #{user.groups}" if user.groups
        cmd += " -k #{user.skel}" if user.skel
        # cmd += " -p #{user.password}" if user.password
        cmd += " -r" if user.system
        cmd += " -s #{user.shell}" if user.shell
        cmd += " -u #{user.uid}" if user.uid
        cmds.push
          cmd: cmd
          code: 0
          code_skipped: 9
      ctx.execute cmds, (err, executed) ->
        return next err if err
        ctx.log 'Update password (changes are not detected)'
        cmds = for user in ctx.config.users
          continue unless user.password
          cmd: "echo #{user.password} | passwd --stdin #{user.username}"
        ctx.execute cmds, (err) ->
          next err, if executed then ctx.OK else ctx.PASS
