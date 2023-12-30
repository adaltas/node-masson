
import quote from 'regexp-quote'

export default
  metadata:
    header: 'Docker Install'
  handler: ({options}) ->
    # Identities
    # Users who belong to the group will be allowed to write into docker sockets and,
    # therefore, use docker commands
    @system.group header: 'Group', options.group
    @system.group header: 'Group dockerroot', options.group_dockerroot
    @system.user header: 'User dockerroot', options.user_dockerroot
    # Install the `docker-io` package on Centos/REHL 6 or `docker` on Centos/REHL 7.
    # Configure it as a startup and started service.
    # Skip Pakage installation, if provided by external deploy tool.
    @tools.repo
      if: options.repo?.source?
      header: 'Repository'
      source: options.repo.source
      target: options.repo.target
      replace: options.repo.replace
      update: true
    @service
      if_os: name: ['redhat','centos'], version: '6'
      header: 'Service'
      name: 'docker'
      yum_name: 'docker-io'
      unless: options.external
      startup: true
    @service
      if_os: name: ['redhat','centos'], version: '7'
      header: 'Service'
      name: 'docker'
      unless: options.external
      yum_name: options.yum_name
      startup: true
    @system.tmpfs
      if_os: name: ['redhat','centos'], version: '7'
      mount: '/var/run/docker'
      name: 'docker'
      perm: '0750'
    # Configuration
    # Note, the options exposed inside the environment variable `OPTIONS` in 
    # "/etc/sysconfig/docker" conflict with the one defined in
    # "/etc/docker/daemon.json". They are not merge, thus preventing Docker to start
    # starting in version 1.13.
    @call header: 'Configuration', ->
      opts = []
      opts.push "--#{k}=#{v}" for k,v of options.other_args
      opts.push '--tlsverify' if options.ssl.enabled
      for type, socketPaths of options.sockets
        opts.push "-H #{type}://#{path}" for path in socketPaths
      if options.block_device
        options.other_opts += """
          --storage-driver=devicemapper \
        --storage-opt=dm.thinpooldev=/dev/mapper/#{options.vg_name}-#{options.thin_pool_name} \
        --storage-opt=dm.use_deferred_removal=true
      """
      writes = [] for key, value of options.env
      options.env['OPTIONS'] ?= "\"#{options.other_opts + ' '+ opts.join ' '}\""
      writes =  for k, v of options.env
        match: RegExp "^#{quote k}=.*$", 'mg'
        replace: "#{k}=#{v}"
        append: true
        @file
          header: 'Daemon'
          if_os: name: ['redhat','centos'], version: '7'
          target: '/etc/docker/daemon.json'
          content: JSON.stringify options.daemon, null, 2
        # @file
        #   header: 'Sysconfig'
        #   unless: options.write_daemon
        #   if_os: name: ['redhat','centos'], version: '7'
        #   target: '/etc/sysconfig/docker'
        #   write: writes
        #   backup: true
        # @file
        #   if_os: name: ['redhat','centos'], version: '6'
        #   target: '/etc/sysconfig/docker'
        #   write: [
        #     match: /^other_args=.*$/mg
        #     replace: "other_args=\"#{}\""
        #   ]
        #   backup: true
    # ## Layout
    # 
    # Open sockets to the docker group
    # 
    #       @call header: 'Sockets permissions', ->
    #         for socket in options.sockets.unix
    #           @system.chown
    #             target: socket
    #             uid: 'root'
    #             gid: options.group.name
    #           @system.chmod
    #             target: socket
    #             mode: 0o660
    # Download Certs
    @call
      if: -> options.ssl.enabled
      header: 'SSL Layout'
    , ->
      @file.download
        target: options.tlscacert
        source: options.ssl.cacert.source
        local: options.ssl.cacert.local
      @file.download
        target: options.tlscert
        source: options.ssl.cert.source
        local: options.ssl.cert.local
      @file.download
        target: options.tlskey
        source: options.ssl.key.source
        local: options.ssl.key.local
        mode: 0o0600
    # Configure Devicemapper
    # For Production use, Docker should have its own devicemapper storage.
    # Inspired from [docker storage setup][docker storage setup].
    # [official doc](https://docs.docker.com/engine/userguide/storagedriver/device-mapper-driver/#configure-direct-lvm-mode-for-production)
    @call
      header: 'Device Mapper'
      if: options.block_device?
    , ->
      @service.install
        name: 'device-mapper-persistent-data lvm2'
      @system.execute
        header: 'Create Physical Volume'
        cmd: """
          pvcreate #{options.block_device}
          """
        unless_exec: "pvdisplay #{options.block_device}"
      @system.execute
        header: 'Volume Group'
        cmd: """
          vgcreate #{options.vg_name} #{options.block_device}
        """
        unless_exec: "vgdisplay #{options.vg_name}"
      @system.execute
        header: 'Create thinpool'
        cmd: """
          lvcreate --wipesignatures y -n #{options.thin_pool_name} #{options.vg_name} -l #{options.thin_pool_size}VG
        """
        unless_exec: "lvdisplay  #{options.vg_name}/#{options.thin_pool_name}"
      @system.execute
        header: 'Create thinpoolmeta lv'
        cmd: """
          lvcreate --wipesignatures y -n #{options.thin_pool_meta_name} #{options.vg_name} -l #{options.thin_pool_meta_size}VG
        """
        unless_exec: "lvdisplay  #{options.vg_name}/#{options.thin_pool_meta_name}"
      @system.execute
        header: 'Convert'
        if: -> @status(-1) or @status(-2)
        cmd: """
          lvconvert -y --zero n -c 512K \
          --thinpool #{options.vg_name}/#{options.thin_pool_name} \
          --poolmetadata #{options.vg_name}/#{options.thin_pool_meta_name}
        """
      @file
        if: -> @status -1
        header: 'LVM Profile'
        target: '/etc/lvm/profile/docker-thinpool.profile'
        content: """
          activation {
            thin_pool_autoextend_threshold=80
            thin_pool_autoextend_percent=20
          }
        """
      @system.execute
        header: 'LVM apply'
        if: -> @status -1
        cmd: """
          lvchange --metadataprofile docker-thinpool  #{options.vg_name}/#{options.thin_pool_name}
        """
      @system.execute
        header: 'LVM Monitor'
        if: -> @status -1
        cmd: """
          lvs -o+seg_monitor
        """
    # Install docker-pid
    # Get the PID of a docker container by name or ID.
    @file
      header: 'docker-pid'
      content: """
      #!/bin/sh
      exec docker inspect --format '{{ .State.Pid }}' "$@"
      """
      target: '/usr/local/bin/docker-pid'
      mode: 0o0755
    # Install docker-ip
    # Get the ip address of a container by name or ID.
    @file
      header: 'docker-ip'
      content: """
      #!/bin/sh
      exec docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$@"
      """
      target: '/usr/local/bin/docker-ip'
      mode: 0o0755
    # Install nsenter
    # `nsenter` is a small tool allowing to enter into namespaces. This is a docker
    # recipe to build nsenter easily and install it in your system. Check 
    # [jpetazzo/nsenter][nsenter] on GitHub.
    # The recipe also install the `docker-enter` command.
    # Important, starting from Docker 1.3 you can use Docker exec to enter a Docker
    # container. There are differences between nsenter and docker exec; namely,
    # nsenter doesn't enter the cgroups, and therefore evades resource limitations.
    # The potential benefit of this would be debugging and external audit, but for
    # remote access, docker exec is the current recommended approach.
    @system.execute
      header: 'nsenter'
      if: options.nsenter
      cmd: """
      docker run -v /usr/local/bin:/target jpetazzo/nsenter
      """
      unless_exec: 'which nsenter'
    # Registry 2.0
    # Docker Registry stores and distributes images centrally. It's where you push
    # images to and pull them from; Docker Registry gives team members the ability to
    # share images and deploy them to testing, staging and production environments.
    #   @system.execute
    #     header: 'Registry 2.0'
    #     cmd: "docker run -p 5000:5000 registry:2.0"
    # Docker Compose
    # Compose is a tool for defining and running multi-container Docker applications.
    @file.assert
      ssh: false
      sudo: false
      target: "#{options.cache_dir}/docker-compose"
    , (err) ->
      throw Error 'Please run "prepare" before "install"' if err
    @file.download
      header: 'Docker Compose'
      source: "#{options.cache_dir}/docker-compose"
      target: '/usr/local/bin/docker-compose'
      local: true
      unless_exec: 'which docker-compose'
    @system.chmod
      target: '/usr/local/bin/docker-compose'
      mode: 0o750
