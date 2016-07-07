
# NodeJs

Deploy multiple version of [NodeJs] using [N].

It depends on the "masson/core/git" and "masson/commons/users" modules. The former
is used to download n and the latest is used to write a "~/.npmrc" file in the
home of each users.

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/commons/git'
    exports.push 'masson/core/users'

## Configuration

*   `nodejs.version` (string)   
    Any NodeJs version with the addition of "latest" and "stable", see the [N] 
    documentation for more information, default to "stable".
*   `nodejs.merge` (boolean)   
    Merge the properties defined in "nodejs.config" with the one present on
    the existing "~/.npmrc" file, default to true
*   `nodejs.config.http_proxy` (string)
    The HTTP proxy connection url, default to the one defined by the 
    "masson/core/proxy" module.
*   `nodejs.config.https-proxy` (string)
    The HTTPS proxy connection url, default to the one defined by the 
    "masson/core/proxy" module.
*   `nodejs.version` (string)
*   `nodejs.version` (string)

Example:

```json
{
  "nodejs": {
    "version": "stable",
    "config": {
      "registry": "http://some.aternative.registry"
    }
  }
}
```

    exports.configure = (ctx) ->
      require('../core/proxy').configure ctx
      ctx.config.nodejs ?= {}
      ctx.config.nodejs.version ?= 'stable'
      ctx.config.nodejs.merge ?= true
      ctx.config.nodejs.config ?= {}
      ctx.config.nodejs.method ?= 'binary' # one of "binary" or "n"
      throw Error 'Method not handled' unless ctx.config.nodejs.method in ['binary', 'n']
      ctx.config.nodejs.config['registry'] ?= 'http://registry.npmjs.org/'
      ctx.config.nodejs.config['proxy'] ?= ctx.config.proxy.http_proxy
      ctx.config.nodejs.config['https-proxy'] ?= ctx.config.proxy.http_proxy

## N Installation

N is a Node.js binary management system, similar to nvm and nave.

    exports.push header: 'Node.js # N', timeout: 100000, handler: ->
      # Accoring to current test, proxy env var arent used by ssh exec
      {method, http_proxy, https_proxy} = @config.nodejs
      env = {}
      env.http_proxy = http_proxy if http_proxy
      env.https_proxy = https_proxy if https_proxy
      @execute
        env: env
        cmd: """
        export http_proxy=#{http_proxy or ''}
        export https_proxy=#{http_proxy or ''}
        cd /tmp
        git clone https://github.com/visionmedia/n.git
        cd n
        make install
        """
        if: method is 'n'
        unless_exists: '/usr/local/bin/n'

## Node.js Installation

Multiple installation of Node.js may coexist with N.

    exports.push header: 'Node.js # installation', timeout: -1, handler: ->
      {method} = @config.nodejs
      @execute
        cmd: "n #{@config.nodejs.version}"
        if: method is 'n'

## NPM configuration

Write the "~/.npmrc" file for each user defined by the "masson/core/users" 
module.

    exports.push header: 'Node.js # Npm Configuration', timeout: -1, handler: ->
      {merge, config} = @config.nodejs
      for user in @config.users do (user) ->
        @write_ini
          target: "#{user.home}/.npmrc"
          content: config
          merge: merge
          uid: user.username
          gid: null
          if:  user.home

[nodejs]: http://www.nodejs.org
[n]: https://github.com/visionmedia/n

## Dependencies

    mecano = require 'mecano'
    misc = require 'mecano/lib/misc'

