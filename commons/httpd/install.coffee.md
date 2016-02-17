
# HTTPD Web Server Install

    module.exports = header: 'HTTPD Install', handler: ->

## IPTables

| Service    | Port | Proto    | Parameter       |
|------------|------|----------|-----------------|
| httpd      | 80   | tcp/http | -               |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

      @iptables
        header: 'IPTables'
        rules: [
          chain: 'INPUT', jump: 'ACCEPT', dport: 80, protocol: 'tcp', state: 'NEW', comment: "HTTPD"
        ]
        if: @config.iptables.action is 'start'

## Users & Groups

By default, the "httpd" package create the following entries:

```bash
cat /etc/passwd | grep pig
apache:x:48:48:Apache HTTPD User:/var/www:/sbin/nologin
cat /etc/group | grep hadoop
apache:x:48:
```

      {group, user} = @config.httpd
      @call header: 'HTTPD # Users & Groups', ->
        @group group
        @user user

## Install

Install the HTTPD service and declare it as a startup service.

      {startup, action} = @config.httpd
      @service
        header: 'HTTPD # Install'
        name: 'httpd'
        startup: startup
        action: action
        timeout: -1
