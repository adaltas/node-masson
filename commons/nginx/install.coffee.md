
# NGINX Web Server Install

    export default header: 'NGINX Install', handler: (options) ->

## Users & Groups

By default, the "nginx" package create the following entries:

```bash
nginx:x:800:799:Nginx web server:/var/lib/nginx:/sbin/nologin
```

      @call header: 'Users & Groups', handler: ->
        @system.group options.group
        @system.user options.user

## Layout

      @call header: 'Layout', handler: ->
        @system.mkdir
          target: options.conf_dir
        @system.mkdir
          target: options.log_dir
          uid: options.user.name
          gid: options.group.name

## Install

Install the nginx service and declare it as a startup service.

      @service
        header: 'Packages'
        name: 'nginx'

## Configuration

      @file.render
        header: 'Configuration'
        target: "#{options.conf_dir}/nginx.conf"
        source: "#{__dirname}/resources/nginx.conf.j2"
        local: true
        context: nginx: options
        backup: true
