---
title: Bind server
module: masson/core/bind_server
layout: module
---

    path = require 'path'
    each = require 'each'
    quote = require 'regexp-quote'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/iptables'

# Bind server

Install and configure [named](http://linux.die.net/man/8/named), a 
Domain Name System (DNS) server, part of the BIND 9 distribution f
rom ISC.

## Configuration

*   `bind_server.zones` (string|array)   
    A list of zone definition files to be uploaded and registered to the named server.   

See the the "resources section" for additional information.

    module.exports.push (ctx) ->
      require('./iptables').configure ctx
      ctx.config.bind_server ?= []
      ctx.config.bind_server.zones ?= []
      if typeof ctx.config.bind_server.zones is 'string'
        ctx.config.bind_server.zones = [ctx.config.bind_server.zones]

## IPTables

| Service    | Port | Proto | Parameter       |
|------------|------|-------|-----------------|
| named      | 53   | tcp   | -               |
| named      | 53   | upd   | -               |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'Bind Server # IPTables', callback: (ctx, next) ->
      {etc_krb5_conf, kdc_conf} = ctx.config.krb5
      rules = []
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 53, protocol: 'tcp', state: 'NEW', comment: "Named" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 53, protocol: 'udp', state: 'NEW', comment: "Named" }
        ]
        if: ctx.config.iptables.action is 'start'
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

## Install

The packages "bind" is installed as a startup item and not yet installed.

    module.exports.push name: 'Bind Server # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service
        name: 'bind'
        srv_name: 'named'
        startup: true
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

## Configure

Update the "/etc/named.conf" file by modifying the commenting the listen-on port
and setting "allow-query" to any. The "named" service is restarted if modified.

    module.exports.push name: 'Bind Server # Configure', callback: (ctx, next) ->
      ctx.write
        destination: '/etc/named.conf'
        write: [
          # Comment listen-on port
          match: /^(\s+)(listen\-on port.*)$/mg
          replace: '$1#$2'
        ,
          # Set allow-query to any
          match: /^(\s+allow\-query\s*\{)(.*)(\};\s*)$/mg
          replace: '$1 any; $3'
        ]
      , (err, written) ->
        return next err if err
        return next null, ctx.PASS unless written
        ctx.service
          name: 'bind'
          srv_name: 'named'
          action: 'restart'
        , (err, restarted) ->
          next err, ctx.OK

## Zones

Upload the zones definition files provided in the configuration file.

    module.exports.push name: 'Bind Server # Zones', callback: (ctx, next) ->
      modified = false
      {zones} = ctx.config.bind_server
      writes = []
      for zone in zones
        writes.push
          # /^zone "hadoop" IN \{[\s\S]*?\n\}/gm.exec f
          match: RegExp "^zone \"#{quote path.basename zone}\" IN \\{[\\s\\S]*?\\n\\};", 'gm'
          replace: """
          zone "#{path.basename zone}" IN {
                  type master;
                  file "#{path.basename zone}";
                  allow-update { none; };
          };
          """
          append: true
      ctx.write
        destination: '/etc/named.conf'
        write: writes
      , (err, written) ->
        return next err if err
        modified = true if written
        each(zones)
        .on 'item', (zone, next) ->
          ctx.log "Upload #{zone}"
          zone =
            source: zone
            destination: "/var/named/#{path.basename zone}"
          ctx.upload zone, (err, uploaded) ->
            modified = true if uploaded
            return next err
        .on 'both', (err) ->
          return next err if err
          return next null, ctx.PASS if not modified
          ctx.log 'Generates configuration files for rndc'
          ctx.execute
            cmd: 'rndc-confgen -a -r /dev/urandom -c /etc/rndc.key'
            not_if_exists: '/etc/rndc.key'
          , (err, executed) ->
            ctx.log 'Restart named service'
            ctx.service
              name: 'bind'
              srv_name: 'named'
              action: 'restart'
            , (err, restarted) ->
              next err, ctx.OK

## Start

Now the service being configured, the "named" service is started.

    module.exports.push name: 'Bind Server # Start', callback: (ctx, next) ->
      ctx.service
        name: 'bind'
        srv_name: 'named'
        action: 'start'
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

## resources

*   [Centos installation](https://www.digitalocean.com/community/articles/how-to-install-the-bind-dns-server-on-centos-6)
*   [Forward configuration](http://gleamynode.net/articles/2267/)




