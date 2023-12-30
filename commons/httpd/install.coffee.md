
# HTTPD Web Server Install

    export default header: 'HTTPD Install', handler: ({options}) ->

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
        if: options.iptables

## Identities

By default, the "httpd" package create the following entries:

```bash
cat /etc/group | grep hadoop
apache:x:48:
cat /etc/passwd | grep apache
apache:x:48:48:Apache HTTPD User:/var/www:/sbin/nologin
```

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Install

Install the HTTPD service and declare it as a startup service.

      @service
        header: 'Install'
        name: 'httpd'
        startup: options.startup
        action: options.action
