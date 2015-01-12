

# Docker Server

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/yum'

    exports.push (ctx) ->
      ctx.config.docker ?= {}
      ctx.config.docker.nsenter ?= true

## Install

Install the `docker-io` package and configure it as a startup and started
service.

    exports.push name: 'Docker # Service', callback: (ctx, next) ->
      ctx.service
        name: 'docker'
        yum_name: 'docker-io'
        startup: true
        action: 'start'
      , next

## Install docker-pid

Get the PID of a docker container by name or ID.

    exports.push name: 'Docker # Install docker-pid', callback: (ctx, next) ->
      ctx.write
        content: """
        #!/bin/sh
        exec docker inspect --format '{{ .State.Pid }}' "$@"
        """
        destination: '/usr/local/bin/docker-pid'
        mode: 0o0755
      , next

## Install docker-ip

Get the ip address of a container by name or ID.

    exports.push name: 'Docker # Install docker-ip', callback: (ctx, next) ->
      ctx.write
        content: """
        #!/bin/sh
        exec docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$@"
        """
        destination: '/usr/local/bin/docker-ip'
        mode: 0o0755
      , next

## Install nsenter

`nsenter` is a small tool allowing to enter into namespaces. This is a docker
recipe to build nsenter easily and install it in your system. Check 
[jpetazzo/nsenter][nsenter] on GitHub.

The recipe also install the `docker-enter` command.

    exports.push name: 'Docker # Install nsenter', callback: (ctx, next) ->
      ctx.execute
        cmd: """
        docker run -v /usr/local/bin:/target jpetazzo/nsenter
        """
        not_if_exec: "which nsenter"
      , next

## Additionnal resources

*   [Setup your own bridge](http://jpetazzo.github.io/2013/10/16/configure-docker-bridge-network/)
*   [Four ways to connect a Docker container](http://blog.oddbit.com/2014/08/11/four-ways-to-connect-a-docker/), providing the `docker-pid` and `docker-ip` scripts.

[nsenter]: http://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/

