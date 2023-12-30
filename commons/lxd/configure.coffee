
export default ({options, node}) ->
  # options.supported_os = ['ubuntu']
  # Identities
  # Group
  options.group = name: options.group if typeof options.group is 'string'
  options.group ?= {}
  options.group.name ?= 'lxd'
  options.group.system ?= true
  options.group.users ?= 'ubuntu'
  # User
  options.user = name: options.user if typeof options.user is 'string'
  options.user ?= {}
  options.user.name ?= 'lxd'
  options.user.gid ?= 'users'
  options.user.system ?= true
  options.user.comment ?= ''
  options.user.home ?= '/var/snap/lxd/common/lxd'
  options.user.shell ?= false
  # Member
  # To allow your user to access the LXD daemon locally, it must be part of the lxd group.
  options.members ?= []
  # Init
  # options.init ?= []
  # options.init['storage-backend'] ?= 'zfs'
  # options.init['storage-pool'] ?= 'lxd'
  # options.init['storage-create-device'] ?= 'no'
  # # Setup loop based storage with SIZE in GB (default -1)
  # options.init['storage-create-loop'] ?= '1'
  # # Address to bind LXD to (default: none)
  # options.init['network-address'] ?= 'none'
  # options.init['network-port'] ?= '-1'
  options.init ?= {}
  options.init.config ?= {}
  options.init.config['core.https_address'] ?= "#{node.ip}:8443"
  options.init.config['core.trust_password'] ?= '3u92j89jfre'
  options.init.networks ?= []
  options.init.storage_pools ?= [
    config: size: '5GB'
    description: ''
    name: 'local'
    driver: 'zfs'
  ]
  options.init.profiles ?= [
    config: {}
    description: ''
    devices:
      root:
        path: '/'
        pool: 'local'
        type: 'disk'
    name: 'default'
  ]
  options.init.cluster ?= {}
  options.init.cluster.server_name ?= "#{node.hostname}"
  options.init.cluster.enabled ?= false
  options.init.cluster.member_config ?= []
  options.init.cluster.cluster_address ?= ''
  options.init.cluster.cluster_certificate ?= ''
  options.init.cluster.server_address ?= ''
  options.init.cluster.cluster_password ?= ''
  # config:
  #   core.https_address: e1.lxd.ryba:8443
  #   core.trust_password: 3u92j89jfre
  # networks: []
  # storage_pools:
  # - config:
  #     size: 5GB
  #   description: ""
  #   name: local
  #   driver: zfs
  # profiles:
  # - config: {}
  #   description: ""
  #   devices:
  #     root:
  #       path: /
  #       pool: local
  #       type: disk
  #   name: default
  # cluster:
  #   server_name: e1
  #   enabled: true
  #   member_config: []
  #   cluster_address: ""
  #   cluster_certificate: ""
  #   server_address: ""
  #   cluster_password: ""
