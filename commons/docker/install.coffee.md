
# Docker Install

    module.exports = header: 'Docker Install', handler: (options) ->
      {docker} = @config
      {ssl, other_args, sockets} = docker
      
## Install

Install the `docker-io` package on Centos/REHL 6 or `docker` on Centos/REHL 7.
Configure it as a startup and started service.
Skip Pakage installation, if provided by external deploy tool.

      @call 
        header: 'Cache Current System'
        handler: discover.system
      @call
        unless: @config.docker.external
        if: -> (options.store['mecano:system:type'] in ['redhat','centos'])
        header: 'Packages'
        handler: ->
          switch options.store['mecano:system:release'][0]
            when '6'
              @service
                header: 'Service'
                name: 'docker'
                yum_name: 'docker-io'
                startup: true
            when '7'
              @service
                header: 'Service'
                name: 'docker'
                yum_name: 'docker'
                startup: true
              @system.tmpfs
                mount: '/var/run/docker'
                name: 'docker'
                perm: '0750'

## Configuration
      
      @call header: 'Daemon Option', handler: ->
        other_opts = @config.docker.other_opts
        opts = []
        opts.push "--#{k}=#{v}" for k,v of other_args
        opts.push '--tlsverify' if ssl.tlsverify
        for type, socketPaths of sockets
          opts.push "-H #{type}://#{path}" for path in socketPaths
        other_opts += opts.join ' '
        @call 
          if: -> (options.store['mecano:system:type'] in ['redhat','centos'])
          handler: ->
            switch options.store['mecano:system:release'][0]
              when '6' 
                @file
                  target: '/etc/sysconfig/docker'
                  write: [
                    match: /^other_args=.*$/mg
                    replace: "other_args=\"#{other_opts}\"" 
                  ]
                  backup: true
              when '7'
                @file
                  target: '/etc/sysconfig/docker'
                  write: [
                    match: /^OPTIONS=.*$/mg
                    replace: "OPTIONS=\"#{other_opts}\"" 
                  ]
                  backup: true

## Download Certs

      @file.download
        source: @config.ryba.ssl.cacert
        destination: ssl.cacert
      @file.download
        source: @config.ryba.ssl.cert
        destination: ssl.cert
      @file.download
        source: @config.ryba.ssl.key
        destination: ssl.key

## Install docker-pid

Get the PID of a docker container by name or ID.

      @file
        header: 'docker-pid'
        content: """
        #!/bin/sh
        exec docker inspect --format '{{ .State.Pid }}' "$@"
        """
        target: '/usr/local/bin/docker-pid'
        mode: 0o0755

## Install docker-ip

Get the ip address of a container by name or ID.

      @file
        header: 'docker-ip'
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
        header: 'nsenter'
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
    #     header: 'Registry 2.0'
    #     cmd: "docker run -p 5000:5000 registry:2.0"    

## Docker Compose
Compose is a tool for defining and running multi-container Docker applications.

      @file.download
        header: 'Docker Compose'
        source: "#{@config.mecano.cache_dir}/docker-compose"
        target: "/usr/local/bin/docker-compose"
        local: true
        unless_exec: 'which docker-compose'
      @chmod
        target: '/usr/local/bin/docker-compose'
        mode: 0o750

## Dependencies

    discover = require 'mecano/lib/misc/discover'

## Additionnal resources

*   [Setup your own bridge](http://jpetazzo.github.io/2013/10/16/configure-docker-bridge-network/)
*   [Four ways to connect a Docker container](http://blog.oddbit.com/2014/08/11/four-ways-to-connect-a-docker/), providing the `docker-pid` and `docker-ip` scripts.

[nsenter]: http://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/
