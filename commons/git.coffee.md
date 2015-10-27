
# GIT

GIT - the stupid content tracker. The recipe will install 
the git client and configure each user. By default, unless
the "global" property is defined, the global property file
in "/etc/gitconfig" will not be created or modified.

    misc = require 'mecano/lib/misc'
    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/users'

Configuration
-------------

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
  "git": {
    "merge": true,
    "global": {
      "user": { "name": 'default user', email: "default_user@domain.com" }
    },
    "users": {
      "a_user": {
        "user": { "name": 'a user', email: "a_user@domain.com" }
        "http": {
          "proxy": "http://some.proxy:9823"
        }
      }
    }
  }
}
```

    exports.configure = (ctx) ->
      require('../core/proxy').configure ctx
      {http_proxy} = ctx.config.proxy
      ctx.config.git ?= {}
      ctx.config.git.merge ?= true
      ctx.config.git.properties ?= {}
      ctx.config.git.proxy ?= true
      ctx.config.git.global ?= false
      ctx.config.git.global = {} if ctx.config.git.global is true
      ctx.config.git.properties.http ?= {}
      ctx.config.git.properties.http.proxy = http_proxy if ctx.config.git.proxy

## Package

Install the git package.

    exports.push name: 'Git # Package', timeout: -1, handler: ->
      @service
        name: 'git'

## Config

Deploy the git configuration.

    exports.push name: 'Git # Config', handler: ->
      {merge, properties, global} = @config.git
      unless @registered 'git_config'
        @register 'git_config', (options) ->
          throw Error unless options.config
          options.content = misc.merge {}, properties, options.config
          options.merge ?= merge
          @ini options
      @git_config
        uid: 'root'
        gid: 'root'
        destination: '/etc/gitconfig'
        config: global
        if: global
      @remove
        if: global is false
        destination: '/etc/gitconfig'
      for user in @config.users then do (user) ->
        @git_config
          destination: file
          uid: user.name or user.uid
          gid: user.gid
