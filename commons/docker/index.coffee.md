
# Docker

Docker allows you to package an application with all of its dependencies into a
standardized unit for software development. Docker containers wrap up a piece of
software in a complete filesystem that contains everything it needs to run:
code, runtime, system tools, system libraries – anything you can install on a
server. This guarantees that it will always run the same, regardless of the
environment it is running in. 

## How To

This modules aims to install docker engine on any host. It does not support docker-cluster
installation. For this purpose you can use `ryba/swarm/manager` and `ryba/swarm/agent`
modules which will bring docker swarm support for the local docker engine.

Indeed this module care about installing docker daemon, configure startup options
setup TLS, sockets etc. Configuration which are mandatory if you want to use docker cluster.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        ssl: implicit: true, module: 'masson/core/ssl'
      configure:
        'masson/commons/docker/configure'
      commands:
        'install': ->
          options = @config.docker
          @call 'masson/commons/docker/install', options
          @call 'masson/commons/docker/start', options
        'prepare': ->
          options = @config.docker
          @call 'masson/commons/docker/prepare', options
        'start': ->
          options = @config.docker
          @call 'masson/commons/docker/start', options
        'status': ->
          options = @config.docker
          @call 'masson/commons/docker/status', options
        'stop': ->
          options = @config.docker
          @call 'masson/commons/docker/status', options
