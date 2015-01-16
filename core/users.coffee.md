
    exports = module.exports = []
    exports.push 'masson/bootstrap'

# Users

A module to create and manage unix users and groups.

## Configuration

    exports.push module.exports.configure = (ctx) ->
      ctx.config.users ?= {}
      ctx.config.groups ?= {}
      for name, user of ctx.config.users
        user.name ?= name
        user.home ?= '/root' if name is 'root'
      for name, group of ctx.config.groups
        group.name ?= name

## Groups

Create the users defined inside the "hdp.groups" configuration. See the
[mecano "group" documentation][mecano_group] for additionnal information.

    exports.push name: 'Groups', handler: (ctx, next) ->
      groups = for _, group in ctx.config.groups then group
      ctx.user groups, next

## Users

Create the users defined inside the "hdp.users" configuration. See the
[mecano "user" documentation][mecano_user] for additionnal information.

    exports.push name: 'Users', handler: (ctx, next) ->
      users = for _, user in ctx.config.users then user
      ctx.user users, next

[mecano_group]: https://github.com/wdavidw/node-mecano/blob/master/src/group.coffee.md
[mecano_user]: https://github.com/wdavidw/node-mecano/blob/master/src/user.coffee.md
