
# Docker Configure

    module.exports = ->
      ctx_iptables = @contexts('masson/core/iptables').filter (ctx) => ctx.config.host is @config.host 
      {ssl} = @config
      options = @config.docker ?= {}
      options.nsenter ?= true
      options.conf_dir ?= '/etc/docker'
      options.group ?= name: 'docker'
      options.group = name: options.group if typeof options.group is 'string'

## Repo
      
      options.repo ?= {}
      options.repo.source ?= null
      options.repo.target ?= '/etc/yum.repos.d/docker-ce.repo'
      options.repo.replace ?= 'docker*'
      # Repo url example for docker community edition 
      #https://download.docker.com/linux/centos/docker-ce.repo"

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
      options.source ?= 'https://github.com/docker/compose/releases/download/1.12.0/docker-compose-Linux-x86_64'
      options.daemon ?= {}
      # the /etc/docker/daemon.json file can also be used to specify starting options for docker daemon

## Docker Environnment
The environment properties are written to /etc/sysconfg/docker file and change how the daemons run.

      options.env ?= {}

## TLS for docker daemon
Docker Engine supports TLS authentication between the CLI and engine.
When TLS is enabled, `tlscacert`, `tlscert`, `tlskey` and `tlsverify` properties
are added docker `@config.docker` object, so it can be used in nikita docker actions.

      options.ssl ?= ssl
      # ptions.ssl.enabled ?= false
      if options.ssl
      # if options.ssl.enabled
        throw Error "Required Option: ssl.cert" if  not options.ssl.cert
        throw Error "Required Option: ssl.key" if not options.ssl.key
        throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
      options.default_port ?= if options.ssl? then 2376 else 2375
      if options.ssl?
        options.env['DOCKER_CERT_PATH'] ?= "#{options.conf_dir}/certs.d"
        options.host ?= "tcp://#{@config.host}:#{options.default_port}"
        # this ca MUST be at #{docker.conf_dir}/certs.d/ca.pem
        options.other_args['tlscacert'] ?= "#{options.env['DOCKER_CERT_PATH']}/ca.pem"
        options.other_args['tlscert'] ?= "#{options.env['DOCKER_CERT_PATH']}/cert.pem"
        options.other_args['tlskey'] ?= "#{options.env['DOCKER_CERT_PATH']}/key.pem"
        # configure tcp socket to  communicate with docker
        tlsverify_socket = "#{@config.host}:#{options.default_port}"
        if (options.sockets.tcp.indexOf tlsverify_socket < 0 )
        then options.sockets.tcp.push tlsverify_socket
        # indeed when executing a nikita.docker action, it will build the docker command
        # to communicate with local daemon engine
        # for example docker --host tcp://master2.ryba:3376 --tlscacert /etc/docker/certs.d/cacert.pem
        # --tlscert /etc/docker/certs.d/cert.pem --tlskey /etc/docker/certs.d/key.pem --tlsverify
        options.tlscacert = options.other_args['tlscacert']
        options.tlscert = options.other_args['tlscert']
        options.tlskey = options.other_args['tlskey']
        options.tlsverify = ' '

## Devicemapper
configure device mapper for production use.It creates a logical volume configured
as a thin pool to use as backing for the storage pool.
To use it just specify the `options.block_device`.

Example
```json
  config: {
    docker: {
      block_device: '/dev/xvdf'
    }
  }

```

      options.block_device ?= null
      options.vg_name ?= 'docker'
      options.thin_pool_name ?= 'thinpool'
      options.thin_pool_size ?= '95%'
      options.thin_pool_meta_name ?= 'thinpoolmeta'
      options.thin_pool_meta_size ?= '1%'
      # options.daemon['storage-driver'] ?= 'devicemapper'
      # options.daemon['storage-opt'] ?=
      #   'dm.thinpooldev': "/dev/mapper/#{options.vg_name}-#{options.thin_pool_name}"
      #   'dm.use_deferred_removal': true
      # options.env['DOCKER_STORAGE_OPTIONS'] ?= 
      

[socket-opts]:(https://docs.docker.com/engine/reference/commandline/dockerd/#/daemon-socket-option)
[daemon-opts-resources]:(https://github.com/moby/moby/issues/21701)
