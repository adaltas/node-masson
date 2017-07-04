
# Docker Configure

    module.exports = ->
      ctx_iptables = @contexts('masson/core/iptables').filter (ctx) => ctx.config.host is @config.host 
      options = @config.docker ?= {}
      options.nsenter ?= true
      options.conf_dir ?= '/etc/docker'

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
  { docker: {
    sockets: {
      unix: ['/var/run/docker.sock'],
      tcp: ['master3.ryba:2376'],
      fd: ['2']
    }
  }
```

      options.sockets ?= {}
      options.sockets.unix ?= ['/var/run/docker.sock']
      options.sockets.tcp ?= []
      options.sockets.fd ?= []
      # Command-line options only supplied to the Docker server when it starts 
      # up, and cannot be changed once it is running.
      # see https://docs.docker.com/v1.5/articles/networking/
      options.other_opts ?= ''
      options.other_args ?= {}
      options.other_args.iptables ?= if ctx_iptables.length and ctx_iptables[0].config.iptables.action is 'start' then 'true' else 'false'
      options.source ?= 'https://github.com/docker/compose/releases/download/1.5.1/docker-compose-Linux-x86_64'

## TLS for docker daemon
Docker Engine supports TLS authentication between the CLI and engine.
When TLS is enabled, `tlscacert`, `tlscert`, `tlskey` and `tlsverify` properties
are added docker `@config.docker` object, so it can be used in nikita docker actions.

      options.ssl ?= {}
      options.ssl.enabled ?= true
      options.default_port ?= if options.ssl.enabled then 2376 else 2375
      if options.ssl.enabled
        options.host ?= "tcp://#{@config.host}:#{options.default_port}"
        # this ca MUST be at #{docker.conf_dir}/certs.d/ca.pem
        options.other_args['tlscacert'] = options.ssl.cacert = "#{options.conf_dir}/certs.d/ca.pem"
        options.other_args['tlscert'] = options.ssl.cert ?= "#{options.conf_dir}/certs.d/cert.pem"
        options.other_args['tlskey'] = options.ssl.key ?= "#{options.conf_dir}/certs.d/key.pem"
        options.ssl.tlsverify ?= true
        tlsverify_socket = "#{@config.host}:#{options.default_port}"
        if (options.sockets.tcp.indexOf tlsverify_socket < 0 ) and options.ssl.tlsverify
        then options.sockets.tcp.push tlsverify_socket
        # indeed when executing a nikita.docker action, it will build the docker command
        # to communicate with local daemon engine
        # for example docker --host tcp://master2.ryba:3376 --tlscacert /etc/docker/certs.d/cacert.pem
        # --tlscert /etc/docker/certs.d/cert.pem --tlskey /etc/docker/certs.d/key.pem --tlsverify
        options.tlscacert = options.ssl.cacert
        options.tlscert = options.ssl.cert
        options.tlskey = options.ssl.key
        options.tlsverify = ' '

[socket-opts]:(https://docs.docker.com/engine/reference/commandline/dockerd/#/daemon-socket-option)
