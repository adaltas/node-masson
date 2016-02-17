
# Users

A module to create and manage unix users and groups.

## Configuration

    module.exports = ->
      @config.users ?= {}
      @config.groups ?= {}
      for name, user of @config.users
        user.name ?= name
        user.home ?= '/root' if name is 'root'
      for name, group of @config.groups
        group.name ?= name
      'install': ->

## Groups

Create the users defined inside the "hdp.groups" configuration. See the
[mecano "group" documentation][mecano_group] for additionnal information.

        @group (
          header: 'Groups'
          name: group
        ) for _, group of @config.groups

## Users

Create the users defined inside the "hdp.users" configuration. See the
[mecano "user" documentation][mecano_user] for additionnal information.
        
        for _, user of @config.users
          user.header = 'Users'
          @user user

    {merge} = require '../lib/misc'

[mecano_group]: https://github.com/wdavidw/node-mecano/blob/master/src/group.coffee.md
[mecano_user]: https://github.com/wdavidw/node-mecano/blob/master/src/user.coffee.md
