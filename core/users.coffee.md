---
title: 
layout: module
---

    module.exports = []
    module.exports.push 'masson/bootstrap/'

# Users

A module to create and manage unix users and groups.

## Configuration

    module.exports.push module.exports.configure = (ctx) ->
      ctx.config.users ?= {}
      ctx.config.groups ?= {}
      for name, user of ctx.config.users
        user.name ?= name
      for name, group of ctx.config.groups
        group.name ?= name

## Groups

Create the users defined inside the "hdp.groups" configuration. See the
[mecano "group" documentation][mecano_group] for additionnal information.

    module.exports.push name: 'Groups', callback: (ctx, next) ->
      groups = for _, group in ctx.config.groups then group
      ctx.user groups, (err, modified) ->
        next err, if modified then ctx.OK else ctx.PASS

## Users

Create the users defined inside the "hdp.users" configuration. See the
[mecano "user" documentation][mecano_user] for additionnal information.

    module.exports.push name: 'Users', callback: (ctx, next) ->
      users = for _, user in ctx.config.users then user
      ctx.user users, (err, modified) ->
        next err, if modified then ctx.OK else ctx.PASS

[mecano_group]: https://github.com/wdavidw/node-mecano/blob/master/src/group.coffee.md
[mecano_user]: https://github.com/wdavidw/node-mecano/blob/master/src/user.coffee.md
