
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

## How to configure

Masson does configure mainly two part of the docker engine:
- TLS
- Startup options

TLS is enabled by adding certificates, and setup startup options, mainly tlsverifiy property.
See the TLS section for the different properties.
When TLS is enabled, a tcp socket must be added to be able to communicate with the docker
daemon engine, as a host in needed to validate certificates. All this options are passed
to `docker.other_args` variable to write it to __/etc/sysconfig/docker__ file.

Startup options are build during the install, and Masson does add to it the different
socket options by reading the `docker.sockets` variable. Three types of socket are available.
Unix, tcp, and fd (file descriptor).

## Sockets for docker daemon

The [Docker daemon][socket-opts] can listen for Docker Remote API requests via three different
types of Socket: unix, tcp, and fd.

Example:

```json
{
  sockets: {
    unix: ["/var/run/docker.sock"],
    tcp: ["master3.ryba:2376"],
    fd: ["2"]
  }
}
```

## TLS for docker daemon

Docker Engine supports TLS authentication between the CLI and engine.
When TLS is enabled, `tlscacert`, `tlscert`, `tlskey` and `tlsverify` properties
are added to the docker configuration, so it can be used by other docker actions.

## Devicemapper

Configure device mapper for production use.It creates a logical volume configured
as a thin pool to use as backing for the storage pool.
To use it just specify the `options.block_device`.

```json
{
  block_device: "/dev/xvdf"
}
```

# Resources

- [socket-opts](https://docs.docker.com/engine/reference/commandline/dockerd/#/daemon-socket-option)
- [daemon-opts-resources](https://github.com/moby/moby/issues/21701)
- [Setup your own bridge](http://jpetazzo.github.io/2013/10/16/configure-docker-bridge-network/)
- [Four ways to connect a Docker container](http://blog.oddbit.com/2014/08/11/four-ways-to-connect-a-docker/), providing the `docker-pid` and `docker-ip` scripts.
- [docker storage setup](https://github.com/projectatomic/container-storage-setup)
[nsenter]: http://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/
