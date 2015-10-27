
# Docker Server

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/yum'

    exports.configure = (ctx) ->
      ctx.config.docker ?= {}
      ctx.config.docker.nsenter ?= true

## Install

Install the `docker-io` package and configure it as a startup and started
service.

    exports.push name: 'Docker # Service', handler: ->
      @service
        name: 'docker'
        yum_name: 'docker-io'
        startup: true
        action: 'start'

## Install docker-pid

Get the PID of a docker container by name or ID.

    exports.push name: 'Docker # Install docker-pid', handler: ->
      @write
        content: """
        #!/bin/sh
        exec docker inspect --format '{{ .State.Pid }}' "$@"
        """
        destination: '/usr/local/bin/docker-pid'
        mode: 0o0755

## Install docker-ip

Get the ip address of a container by name or ID.

    exports.push name: 'Docker # Install docker-ip', handler: ->
      @write
        content: """
        #!/bin/sh
        exec docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$@"
        """
        destination: '/usr/local/bin/docker-ip'
        mode: 0o0755

## Install nsenter

`nsenter` is a small tool allowing to enter into namespaces. This is a docker
recipe to build nsenter easily and install it in your system. Check 
[jpetazzo/nsenter][nsenter] on GitHub.

The recipe also install the `docker-enter` command.

Important, starting from Docker 1.3 you can use Docker exec to enter a Docker
container. There are differences between nsenter and docker exec; namely,
nsenter doesn't enter the cgroups, and therefore evades resource limitations.
The potential benefit of this would be debugging and external audit, but for
remote access, docker exec is the current recommended approach.

    exports.push name: 'Docker # Install nsenter', handler: ->
      @execute
        cmd: """
        docker run -v /usr/local/bin:/target jpetazzo/nsenter
        """
        not_if_exec: "which nsenter"

## Registry 2.0

Docker Registry stores and distributes images centrally. It's where you push
images to and pull them from; Docker Registry gives team members the ability to
share images and deploy them to testing, staging and production environments.

    # exports.push name: 'Docker # Registry 2.0', handler: ->
    #   @execute
    #     cmd: "docker run -p 5000:5000 registry:2.0"    

## Additionnal resources

*   [Setup your own bridge](http://jpetazzo.github.io/2013/10/16/configure-docker-bridge-network/)
*   [Four ways to connect a Docker container](http://blog.oddbit.com/2014/08/11/four-ways-to-connect-a-docker/), providing the `docker-pid` and `docker-ip` scripts.

[nsenter]: http://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/
