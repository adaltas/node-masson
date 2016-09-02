
# Bind server Install

    module.exports = header: 'Bind Server Install', handler: ->
      {bind_server} = @config

## Users & Groups

By default, the "bind" package create the following entries:

```bash
cat /etc/passwd | grep named
named:x:25:25:Named:/var/named:/sbin/nologin
cat /etc/group | grep named
named:x:25:
```

      @group bind_server.group
      @user bind_server.user

## IPTables

| Service    | Port | Proto | Parameter       |
|------------|------|-------|-----------------|
| named      | 53   | tcp   | -               |
| named      | 53   | upd   | -               |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 53, protocol: 'tcp', state: 'NEW', comment: "Named" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 53, protocol: 'udp', state: 'NEW', comment: "Named" }
        ]
        if: @config.iptables.action is 'start'

## Install

The packages "bind" is installed as a startup item and not yet installed.

      @service
        header: 'Install'
        name: 'bind'
        srv_name: 'named'
        startup: true

## Configure

Update the "/etc/named.conf" file by modifying the commenting the listen-on port
and setting "allow-query" to any. The "named" service is restarted if modified.

      @file
        header: 'Configure'
        target: '/etc/named.conf'
        write: [
          # Comment listen-on port
          match: /^(\s+)(listen\-on port.*)$/mg
          replace: '$1#$2'
        ,
          # Set allow-query to any
          match: /^(\s+allow\-query\s*\{)(.*)(\};\s*)$/mg
          replace: '$1 any; $3'
        ]
      @service
        header: 'Restart'
        srv_name: 'named'
        action: 'restart'
        if: -> @status -1

## Zones

Upload the zones definition files provided in the configuration file.   

      @call header: 'Zones', handler: ->
        @file
          target: '/etc/named.conf'
          write: for zone in bind_server.zones
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
        @file (
          source: zone
          local: true
          target: "/var/named/#{path.basename zone}"
        ) for zone in bind_server.zones

## rndc Key

Generates configuration files for rndc.   

      @call header: 'Bind Server # rndc Key', handler: ->
        @execute
          cmd: 'rndc-confgen -a -r /dev/urandom -c /etc/rndc.key'
          unless_exists: '/etc/rndc.key'
        @chown
          target: '/etc/rndc.key'
          uid: bind_server.user.name
          gid: bind_server.group.name
        @service
          srv_name: 'named'
          action: 'restart'
          if: -> @status()

## Module Dependencies

    path = require 'path'
    quote = require 'regexp-quote'

## Resources

*   [Centos installation](https://www.digitalocean.com/community/articles/how-to-install-the-bind-dns-server-on-centos-6)
*   [Forward configuration](http://gleamynode.net/articles/2267/)
