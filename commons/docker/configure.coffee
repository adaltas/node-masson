
import { merge } from 'mixme'

export default (service) ->
  options = service.options
  # Identities
  # Group
  options.group ?= {}
  options.group = name: options.group if typeof options.group is 'string'
  options.group.name ?= 'docker'
  options.group_dockerroot ?= {}
  options.group_dockerroot = name: options.group if typeof options.group is 'string'
  options.group_dockerroot.name ?= 'dockerroot'
  # User
  options.user_dockerroot ?= {}
  options.user_dockerroot = name: options.user_dockerroot if typeof options.user_dockerroot is 'string'
  options.user_dockerroot.name ?= 'dockerroot'
  options.user_dockerroot.home ?= "/var/lib/#{options.user_dockerroot.name}"
  options.user_dockerroot.gid ?= options.group_dockerroot.name
  # Environment
  options.nsenter ?= true
  options.conf_dir ?= '/etc/docker'
  # Repo
  options.repo ?= {}
  options.repo.source ?= null
  options.repo.target ?= '/etc/yum.repos.d/docker-ce.repo'
  options.repo.replace ?= 'docker*'
  # Repo url example for docker community edition 
  #https://download.docker.com/linux/centos/docker-ce.repo"
  options.sockets ?= {}
  options.sockets.unix ?= ['/var/run/docker.sock']
  options.sockets.tcp ?= []
  options.sockets.fd ?= []
  # Command-line options only supplied to the Docker server when it starts 
  # up, and cannot be changed once it is running.
  # see https://docs.docker.com/v1.5/articles/networking/
  options.other_opts ?= ''
  options.other_args ?= {}
  options.other_args.iptables ?= if service.deps.iptables and service.deps.iptables.options.action is 'start' then 'true' else 'false'
  options.source ?= 'https://github.com/docker/compose/releases/download/1.13.0/docker-compose-Linux-x86_64'
  options.daemon ?= {}
  options.daemon.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
  # the /etc/docker/daemon.json file can also be used to specify starting options for docker daemon
  # Docker Environment
  # The environment properties are written to /etc/sysconfg/docker file and change how the daemons run.
  options.env ?= {}
  options.ssl = merge service.deps.ssl?.options, options.ssl
  options.ssl.enabled ?= !!service.deps.ssl
  unless options.ssl.enabled
    options.default_port ?= 2375
  else
    options.default_port ?= 2376
    throw Error "Required Option: ssl.cert" if  not options.ssl.cert
    throw Error "Required Option: ssl.key" if not options.ssl.key
    throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
    options.env['DOCKER_CERT_PATH'] ?= "#{options.conf_dir}/certs.d"
    # options.write_daemon ?= false        
    # this ca MUST be at #{docker.conf_dir}/certs.d/ca.pem
    # options.other_args['tlscacert'] ?= "#{options.env['DOCKER_CERT_PATH']}/ca.pem"
    # options.other_args['tlscert'] ?= "#{options.env['DOCKER_CERT_PATH']}/cert.pem"
    # options.other_args['tlskey'] ?= "#{options.env['DOCKER_CERT_PATH']}/key.pem"
    # configure tcp socket to  communicate with docker
    # indeed when executing a nikita.docker action, it will build the docker command
    # to communicate with local daemon engine
    # for example docker --host tcp://master2.ryba:3376 --tlscacert /etc/docker/certs.d/cacert.pem
    # --tlscert /etc/docker/certs.d/cert.pem --tlskey /etc/docker/certs.d/key.pem --tlsverify
    options.tlscacert = "#{options.env['DOCKER_CERT_PATH']}/ca.pem"
    options.tlscert = "#{options.env['DOCKER_CERT_PATH']}/cert.pem"
    options.tlskey = "#{options.env['DOCKER_CERT_PATH']}/key.pem"
    options.tlsverify = ' '
    tlsverify_socket = "#{service.node.fqdn}:#{options.default_port}"
    options.sockets.tcp.push tlsverify_socket if options.sockets.tcp.indexOf tlsverify_socket < 0
    options.daemon['tls'] ?= true
    options.daemon['tlscert'] ?= options.tlscert
    options.daemon['tlskey'] ?= options.tlskey
    options.daemon['tlscacert'] ?= options.tlscacert
  # Global variable to run docker commands
  options.host ?= "tcp://#{service.node.fqdn}:#{options.default_port}"
  options.daemon['hosts'] ?= []
  options.tcp_only ? false
  if not options.tcp_only
    options.daemon['hosts'].push 'unix:///var/run/docker.sock' if options.daemon['hosts'].indexOf('unix:///var/run/docker.sock') is -1
  options.daemon.hosts.push options.host unless options.host in options.daemon.hosts
  # Allow Other package name
  # In the case adminsitrators want to install docker-ce, the yum name must be docker-ce instead of docker. 
  options.yum_name ?= 'docker'
  options.srv_name ?= 'docker'
  # Live restore
  #let container in running state when the docker daemon does not run
  # useful on production cluster for maintenance operations
  options.daemon['live-restore'] ?= false
  options.block_device ?= null
  if options.block_device?
    options.vg_name ?= 'docker'
    options.thin_pool_name ?= 'thinpool'
    options.thin_pool_size ?= '95%'
    options.thin_pool_meta_name ?= 'thinpoolmeta'
    options.thin_pool_meta_size ?= '1%'
    options.daemon['storage-driver'] ?= 'devicemapper'
    options.daemon['storage-opt'] ?=
      'dm.thinpooldev': "/dev/mapper/#{options.vg_name}-#{options.thin_pool_name}"
      'dm.use_deferred_removal': true
    # options.env['DOCKER_STORAGE_OPTIONS'] ?= 
  # Command Specific
  # Ensure "prepare" is executed locally only once
  options.prepare = service.node.id is service.instances[0].node.id
