---
title: 
layout: module
---

    path = require 'path'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/users'

# Proxy

Declare proxy related environment variables as well as 
providing configuration properties which other modules may use.

## Configuration

Configuration is declared through the key "proxy" and may 
contains the following properties:

*   `system`
    Should the proxy environment variable be written inside the
    system-wide "/etc/profile.d" directory. Default to false
*   `system_file`
    The path where to place a shell script to export
    proxy environmental variables, default to 
    "phyla_proxy.sh". Unless absolute, the path will 
    be relative to "/etc/profile.d". If false, no
    file will be created.
*   `host`
    The proxy host, not required. The value will determine
    wether or not we use proxying
*   `port`
    The proxy port, not required
*   `username`
    The proxy username, not required
*   `password`
    The proxy password, not required
*   `secure`
    An object with the same `host`, `port`, `username` and
    `password` property but used for secure https proxy. it
    default to the default http settings.

If at least the `host` property is defined, the 
configuration will be enriched with the `http_proxy`, the
`https_proxy`, the `http_proxy_no_auth` and the 
`https_proxy_no_auth` urls properties.

    module.exports.push module.exports.configure = (ctx) ->
      ctx.config.proxy ?= {}
      ctx.config.proxy.system ?= false
      ctx.config.proxy.system_file ?= "phyla_proxy.sh"
      if ctx.config.proxy.system_file
        ctx.config.proxy.system_file = path.resolve '/etc/profile.d', ctx.config.proxy.system_file
      ctx.config.proxy.host ?= null
      ctx.config.proxy.port ?= null
      ctx.config.proxy.username ?= null
      ctx.config.proxy.password ?= null
      ctx.config.proxy.secure ?= null
      if not ctx.config.proxy.host and (ctx.config.proxy.port or ctx.config.proxy.username or ctx.config.proxy.password)
        return next new Error "Invalid proxy configuration"
      toUrl = (scheme, auth) ->
        return null unless ctx.config.proxy.host
        if scheme is 'https' and ctx.config.proxy.secure?.host
          config = ctx.config.proxy.secure
        else
          config = ctx.config.proxy
        {host, port, username, password} = config
        url = "#{scheme}://"
        if auth
          url = "#{url}#{username}" if username
          url = "#{url}:#{password}" if password
          url = "#{url}@" if username
        url = "#{url}#{host}"
        url = "#{url}:#{port}" if port
        url
      ctx.config.proxy.http_proxy = toUrl 'http', true
      ctx.config.proxy.https_proxy = toUrl 'https', true
      ctx.config.proxy.http_proxy_no_auth = toUrl 'http', false
      ctx.config.proxy.https_proxy_no_auth = toUrl 'https', false

## Profile

Declare the http_proxy and "https_proxy" environment
variables by declaring a shell script inside the 
profile initialization directory.

    module.exports.push name: 'Proxy # Profile', callback: (ctx, next) ->
      # There is no proxy to configure
      return next() unless ctx.config.proxy.http_proxy
      return next null, ctx.DISABLED
      # {system, http_proxy, https_proxy} = ctx.config.proxy
      # modified = 0
      # write = (file, callback) ->
      #   ctx.write [
      #     match: /.*http_proxy.*/
      #     replace: "{if system and http_proxy then '' else '#'}export http_proxy=#{http_proxy}"
      #     destination: file
      #     append: true
      #   ,
      #     match: /.*https_proxy.*/
      #     replace: "{if system and https_proxy then '' else '#'}export https_proxy=#{https_proxy}"
      #     destination: file
      #     append: true
      #   ], (err, written) ->
      #     modified++ if written
      #     callback()
      # # System wide
      # write ctx.config.proxy.system_file, (err) ->
      #   return next err if err
      #   each(ctx.config.users)
      #   .on 'item', (user, next) ->
      #     return next() unless user.home
      #     file = path.resolve user.home, '.bash_profile'
      #     write file, next
      #   .on 'both', (err) ->
      #     next err, if modified then ctx.OK else ctx.PASS








