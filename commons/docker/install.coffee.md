
# Docker Install

    module.exports = handler: (options) ->
    
## Install

Install the `docker-io` package and configure it as a startup and started
service.

      @service
        header: 'Docker # Service'
        name: 'docker'
        yum_name: 'docker-io'
        startup: true
        action: 'start'

## Configuration

      other_args = for k, v of options.other_args then "--#{k}=#{v}"
      @write
        target: '/etc/sysconfig/docker'
        write: [
          match: /^other_args=.*$/m
          replace: "other_args=\"#{other_args.join ' '}\""
        ]
        backup: true

## Install docker-pid

Get the PID of a docker container by name or ID.

      @write
        header: 'Docker # Install docker-pid'
        content: """
        #!/bin/sh
        exec docker inspect --format '{{ .State.Pid }}' "$@"
        """
        target: '/usr/local/bin/docker-pid'
        mode: 0o0755

## Install docker-ip

Get the ip address of a container by name or ID.

      @write
        header: 'Docker # Install docker-ip'
        content: """
        #!/bin/sh
        exec docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$@"
        """
        target: '/usr/local/bin/docker-ip'
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

      @execute
        header: 'Docker # Install nsenter'
        if: options.nsenter
        cmd: """
        docker run -v /usr/local/bin:/target jpetazzo/nsenter
        """
        unless_exec: "which nsenter"

## Registry 2.0

Docker Registry stores and distributes images centrally. It's where you push
images to and pull them from; Docker Registry gives team members the ability to
share images and deploy them to testing, staging and production environments.

    #   @execute
    #     header: 'Docker # Registry 2.0'
    #     cmd: "docker run -p 5000:5000 registry:2.0"    

## Additionnal resources

*   [Setup your own bridge](http://jpetazzo.github.io/2013/10/16/configure-docker-bridge-network/)
*   [Four ways to connect a Docker container](http://blog.oddbit.com/2014/08/11/four-ways-to-connect-a-docker/), providing the `docker-pid` and `docker-ip` scripts.

[nsenter]: http://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/
