---
title: NodeJs
module: phyla/hadoop/nodejs
layout: module
---

# NodeJs

Deploy multiple version of [NodeJs] using [N].

It depends on the "masson/core/git" and "masson/commons/users" modules. The former
is used to download n and the latest is used to write a "~/.npmrc" file in the
home of each users.

    ini = require 'ini'
    each = require 'each'
    mecano = require 'mecano'
    misc = require 'mecano/lib/misc'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/commons/git'
    module.exports.push 'masson/core/users'
    module.exports.push require('../core/proxy').configure

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

    module.exports.push (ctx, next) ->
      ctx.config.nodejs ?= {}
      ctx.config.nodejs.version ?= 'stable'
      ctx.config.nodejs.merge ?= true
      ctx.config.nodejs.config ?= {}
      ctx.config.nodejs.method ?= 'binary' # one of "binary" or "n"
      ctx.config.nodejs.config['registry'] ?= 'http://registry.npmjs.org/'
      ctx.config.nodejs.config['proxy'] ?= ctx.config.proxy.http_proxy
      ctx.config.nodejs.config['https-proxy'] ?= ctx.config.proxy.http_proxy
      next()

## N Installation

N is a Node.js binary management system, similar to nvm and nave.

    module.exports.push name: 'Node.js # N', timeout: 100000, callback: (ctx, next) ->
      # Accoring to current test, proxy env var arent used by ssh exec
      {method, http_proxy, https_proxy} = ctx.config.nodejs
      return next() unless method is 'n'
      env = {}
      env.http_proxy = http_proxy if http_proxy
      env.https_proxy = https_proxy if https_proxy
      ctx.execute
        env: env
        cmd: """
        export http_proxy=#{http_proxy or ''}
        export https_proxy=#{http_proxy or ''}
        cd /tmp
        git clone https://github.com/visionmedia/n.git
        cd n
        make install
        """
        not_if_exists: '/usr/local/bin/n'
      , (err, executed) ->
        next err, if executed then ctx.OK else ctx.PASS

## Node.js Installation

Multiple installation of Node.js may coexist with N.

    module.exports.push name: 'Node.js # installation', timeout: -1, callback: (ctx, next) ->
      if method is 'n'
        ctx.execute
          cmd: "n #{ctx.config.nodejs.version}"
        , (err, executed) ->
          next err, if executed is 0 then ctx.OK else ctx.PASS
      else
        console.log 'not ready'


## NPM configuration

Write the "~/.npmrc" file for each user defined by the "masson/core/users" 
module.

    module.exports.push name: 'Node.js # Npm Configuration', timeout: -1, callback: (ctx, next) ->
      {merge, config} = ctx.config.nodejs
      modified = false
      each(ctx.config.users)
      .on 'item', (user, next) ->
        return next() unless user.home
        ctx.write
          destination: "#{user.home}/.npmrc"
          content: config
          merge: merge
          uid: user.username
          gid: null
        , (err, written) ->
          modified = true if written
          next err
      .on 'both', (err) ->
        next err, if modified then ctx.OK else ctx.PASS

[nodejs]: http://www.nodejs.org
[n]: https://github.com/visionmedia/n

