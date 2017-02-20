
# HTTPD Web Server Install

    module.exports = header: 'HTTPD Install', handler: ->
      {httpd} = @config

## IPTables

| Service    | Port | Proto    | Parameter       |
|------------|------|----------|-----------------|
| httpd      | 80   | tcp/http | -               |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          chain: 'INPUT', jump: 'ACCEPT', dport: 80, protocol: 'tcp', state: 'NEW', comment: "HTTPD"
        ]
        if: @config.iptables.action is 'start'

## Users & Groups

By default, the "httpd" package create the following entries:

```bash
cat /etc/passwd | grep apache
apache:x:48:48:Apache HTTPD User:/var/www:/sbin/nologin
cat /etc/group | grep hadoop
apache:x:48:
```

      @call header: 'Users & Groups', handler: ->
        @system.group httpd.group
        @system.user httpd.user

## Install

Install the HTTPD service and declare it as a startup service.

      @service
        header: 'Install'
        name: 'httpd'
        startup: httpd.startup
        action: httpd.action
        timeout: -1
