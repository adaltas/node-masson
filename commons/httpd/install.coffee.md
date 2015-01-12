
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

    exports.push name: 'HTTPD # IPTables', callback: (ctx, next) ->
      {etc_krb5_conf, kdc_conf} = ctx.config.krb5
      rules = []
      ctx.iptables
        rules: [
          chain: 'INPUT', jump: 'ACCEPT', dport: 80, protocol: 'tcp', state: 'NEW', comment: "HTTPD"
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Users & Groups

By default, the "httpd" package create the following entries:

```bash
cat /etc/passwd | grep pig
apache:x:48:48:Apache HTTPD User:/var/www:/sbin/nologin
cat /etc/group | grep hadoop
apache:x:48:
```

    exports.push name: 'HTTPD # Users & Groups', callback: (ctx, next) ->
      {group, user} = ctx.config.httpd
      ctx.group group, (err, gmodified) ->
        return next err if err
        ctx.user user, (err, umodified) ->
          next err, gmodified or umodified

## Install

Install the HTTPD service and declare it as a startup service.

    exports.push name: 'HTTPD # Install', timeout: -1, callback: (ctx, next) ->
      {startup, action} = ctx.config.httpd
      ctx.service
        name: 'httpd'
        startup: startup
        action: action
      , next