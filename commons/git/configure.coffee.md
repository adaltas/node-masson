
# Git Configure

*   `properties`
    Git configuration shared by all users and the global
    configuration file.
*   `global`
    The configation properties used to generate
    the global configuration file in "/etc/gitconfig" or `null`
    if no global configuration file should be created, default
    to `null`.
*   `merge`
    Whether or not to merge the 'git.config' content
    with the one present on the server. Declared
    configuration preveils over the already existing
    one on the server.
*   `proxy`
    Inject proxy configuration as declared in the
    proxy action, default is true

Configuration example:

This exemple will create a global configuration file
in "/etc/gitconfig" and a user configuration file for
user "a_user". It defines its own proxy configuration, disregarding
any settings from the proxy action.

```json
{
  "merge": true,
  "global": {
    "user": { "name": "default user", email: "default_user@domain.com" }
  },
  "users": {
    "a_user": {
      "user": { "name": "a user", email: "a_user@domain.com" },
      "http": {
        "proxy": "http://some.proxy:9823"
      }
    }
  }
}
```

    module.exports = (service) ->
      options = service.options

## Environment

      options.merge ?= true
      options.proxy ?= true
      options.global ?= false
      options.global = {} if options.global is true

## Configuration

      options.properties ?= {}
      options.properties.http ?= {}
      options.properties.http.proxy ?= service.deps.proxy.options.http_proxy if service.deps.proxy and options.proxy

## User Configuration

Npm properties can be defined by the system module through the "gitconfig" user 
configuration.

      options.users ?= {}
      for username, user of options.users
        throw Error "User Not Defined: module system must define the user #{username}" unless service.deps.system.options.users[username]
        user = merge {}, service.deps.system.options.users[username], user
        user.target ?= "#{user.home}/.gitconfig"
        user.uid ?= user.uid or user.name
        user.gid ?= user.gid or user.group
        user.content ?= merge {}, options.properties, user.gitconfig, user.properties
        user.merge ?= options.merge

## Dependencies

    {merge} = require '@nikita/core/lib/misc'
      
