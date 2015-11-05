
# HTTPD Web Server Install

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/iptables'

## IPTables

| Service    | Port | Proto    | Parameter       |
|------------|------|----------|-----------------|
| httpd      | 80   | tcp/http | -               |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    exports.push header: 'HTTPD # IPTables', handler: ->
      {etc_krb5_conf, kdc_conf} = @config.krb5
      rules = []
      @iptables
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

    exports.push header: 'HTTPD # Users & Groups', handler: ->
      {group, user} = @config.httpd
      @group group
      @user user

## Install

Install the HTTPD service and declare it as a startup service.

    exports.push header: 'HTTPD # Install', timeout: -1, handler: ->
      {startup, action} = @config.httpd
      @service
        name: 'httpd'
        startup: startup
        action: action
