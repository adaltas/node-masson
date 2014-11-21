
# Bind server Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/iptables'
    module.exports.push require('./index').confiugre

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
      , next

## Install

The packages "bind" is installed as a startup item and not yet installed.

    module.exports.push name: 'Bind Server # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service
        name: 'bind'
        srv_name: 'named'
        startup: true
      , next

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
        return next null, false unless written
        ctx.service
          srv_name: 'named'
          action: 'restart'
        , next

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
          return next null, false if not modified
          ctx.log 'Generates configuration files for rndc'
          ctx.execute
            cmd: 'rndc-confgen -a -r /dev/urandom -c /etc/rndc.key'
            not_if_exists: '/etc/rndc.key'
          , (err, executed) ->
            ctx.log 'Restart named service'
            ctx.service
              srv_name: 'named'
              action: 'restart'
            , next

## Module Dependencies

    path = require 'path'
    each = require 'each'
    quote = require 'regexp-quote'

## resources

*   [Centos installation](https://www.digitalocean.com/community/articles/how-to-install-the-bind-dns-server-on-centos-6)
*   [Forward configuration](http://gleamynode.net/articles/2267/)




