---
title: DNS
module: masson/core/dns
layout: module
---

# DNS

Forward and reverse DNS mandatory to many service. For exemple both Kerberos 
and Hadoop require a working DNS environment to work properly. A common 
solution to solve an incorrect DNS environment is to install your own DNS 
server. Investigate the "masson/core/bind_server" module for additional 
information.

TODO: in case we are running a local bind server inside the cluster and if this 
server isnt the one currently being installed, we could wait for the server to 
be started before checking the forward and reverse dns of the server.

Dig isn't available by default on CentOS and is installed by the 
"masson/core/bind_client" dependency.

    ipRegex = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/bind_client'

## Forward Lookup

    module.exports.push name: 'DNS # `dig` Forward Lookup', callback: (ctx, next) ->
      # I didnt find how to restrict dig to return only A records like it
      # does for CNAME records if you append "cname" at the end of the command.
      # I assume the A record to always be printed on the last line.
      ctx.execute
        cmd: "dig #{ctx.config.host}. +short"
        code_skipped: 1
      , (err, executed, stdout, stderr) ->
        if err
          next err
        else unless ipRegex.test stdout.split(/\s+/).shift()
          ctx.log "Invalid IP #{stdout.trim()}"
          next null, ctx.WARN
        else
         next null, ctx.PASS

## Reverse Lookup

    module.exports.push name: 'DNS # `dig` Reverse Lookup', callback: (ctx, next) ->
      ctx.execute
        cmd: "dig -x #{ctx.config.ip} +short"
        code_skipped: 1
      , (err, executed, stdout) ->
        next err, if "#{ctx.config.host}." is stdout.trim() then ctx.PASS else ctx.WARN

## Forward Lookup with getent

    module.exports.push name: 'DNS # `getent` Forward Lookup', callback: (ctx, next) ->
      ctx.execute
        cmd: "getent hosts #{ctx.config.host}"
        code_skipped: 2
      , (err, valid, stdout, stderr) ->
        return next err if err
        return next null, ctx.WARN if not valid
        [ip, fqdn] = stdout.split(/\s+/).filter( (entry) -> entry)
        next null, if ip is ctx.config.ip and fqdn is ctx.config.host then ctx.PASS else ctx.WARN

## Reverse Lookup with getent

    module.exports.push name: 'DNS # `getent` Reverse Lookup', callback: (ctx, next) ->
      ctx.execute
        cmd: "getent hosts #{ctx.config.ip}"
        code_skipped: 2
      , (err, valid, stdout) ->
        return next err if err
        return next null, ctx.WARN if not valid
        [ip, fqdn] = stdout.split(/\s+/).filter( (entry) -> entry)
        next null, if ip is ctx.config.ip and fqdn is ctx.config.host then ctx.PASS else ctx.WARN

## Hostname

    module.exports.push name: 'DNS # Hostname', callback: (ctx, next) ->
      ctx.execute
        cmd: "hostname"
      , (err, _, stdout) ->
        return next err if err
        next null, if stdout.trim() is ctx.config.host then ctx.PASS else ctx.WARN



