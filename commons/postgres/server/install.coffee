
export default
  metadata:
    header: 'PostgreSQL Server Install'
  handler: (options) ->
    @tools.iptables
      header: 'IPTables'
      rules: [
        { chain: 'INPUT', jump: 'ACCEPT', dport: options.port, protocol: 'tcp', state: 'NEW', comment: "PostgreSQL" }
      ]
      if: options.iptables
    # Startup Script
    @service.init
      header: 'Startup Script'
      source: "#{__dirname}/resources/postgres-server.j2"
      local: true
      target: "/etc/init.d/postgres-server"
      context: container: options.container_name
    # Package
    # Install the PostgreSQL database server.
    @system.discover (err, status, os) ->
      @call header: 'Download Container', handler: ->
        exists = false
        @docker.checksum
          image: 'postgresql'
          tag: postgres.version
          docker: if os.type in ['redhat','centos'] and os.release[0] is '6'
          then null
          else @config.docker #can not enable tls client verification centos/redhat6
        , (err, status, checksum) ->
          throw err if err
          exists = true if checksum
        @file.download
          unless: -> exists
          binary: true
          md5: true
          source: "#{@config.nikita.cache_dir}/postgres.tar"
          target: "#{options.image_dir}/postgres.tar"
        @docker.load
          header: 'Load Container'
          unless: -> exists
          source: "#{options.image_dir}/postgres.tar"
          docker: if os.type in ['redhat','centos'] and os.release[0] is '6'
          then null
          else @config.docker #can not enable tls client verification centos/redhat6
      # Run Container
      # Run the PostgreSQL server container
      @docker.service
        machine: @config.nikita.machine
        header: 'Run PostgreSQL Container'
        force: -> @status(-1)
        image: "postgres:#{options.version}"
        env: [
          "POSTGRES_PASSWORD=#{options.password}"
          "POSTGRES_USER=#{options.user}"
        ]
        port: "#{options.port}:5432"
        service: true
        name: options.container_name
        docker: if os.type in ['redhat','centos'] and os.release[0] is '6'
        then null
        else @config.docker #can not enable tls client verification centos/redhat6
