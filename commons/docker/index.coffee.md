
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
      deps:
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: 'masson/core/ssl', local: true
      configure:
        'masson/commons/docker/configure'
      commands:
        'check':
          'masson/commons/docker/check'
        'install': [
          'masson/commons/docker/install'
          'masson/commons/docker/start'
          'masson/commons/docker/check'
        ]
        'prepare':
          'masson/commons/docker/prepare'
        'start':
          'masson/commons/docker/start'
        'status':
          'masson/commons/docker/status'
        'stop':
          'masson/commons/docker/status'
